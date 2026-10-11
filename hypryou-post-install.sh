#!/usr/bin/env bash
#
# hypryou-post-install.sh
#
# Idempotent post-install / post-upgrade fixes for HyprYou (AUR: hypryou,
# hypryou-utils). hypryou upgrades restore the stock files, so run this again
# after every install or upgrade.
#
#   1. main.lua load order: load the user config last, after the generated one.
#   2. ly restart policy: keep the session alive after it exits (every tty).
#   3. GTK decoration layout: hide window buttons (empty layout).
#   4. Bar workspace buttons: reset leftover theme button chrome (stray rings).
#
# Usage: ./hypryou-post-install.sh

set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    echo "error: do not run as root." >&2
    echo "       step 3 writes GTK config under \$HOME, which would target /root." >&2
    echo "       run as your normal user; the script uses sudo where it needs it." >&2
    exit 1
fi

MAIN_LUA="/usr/share/hypryou/hyprland/main.lua"
MAIN_BACKUP="/var/backups/hypryou-main.lua.orig"
# Drop-in on the template, not on ly@ttyN: the instance number varies per
# machine (e.g. ly@tty3.service here), and only the template path applies to
# every instance.
LY_DROPIN_DIR="/etc/systemd/system/ly@.service.d"
LY_DROPIN="${LY_DROPIN_DIR}/restart.conf"
AUTOSTART_BACKUP="/var/backups/hypryou-autostart.lua.orig"

BAR_SCSS="/usr/share/hypryou/scss/_bar.scss"
BAR_BACKUP="/var/backups/hypryou-_bar.scss.orig"
BAR_MARKER='/* hypryou-post-install: reset theme button chrome on workspace buttons */'

USER_LINE='dofileOrCreate(os.getenv("HOME") .. "/.config/hypryou/hyprland.lua")'
GEN_LINE='dofileOrCreate(os.getenv("HOME") .. "/.config/hypryou/hyprland_generated.lua")'
COMMENT='-- Load the user config last so its unbind/bind calls win over the settings file.'

TMP=""
TMP2=""
trap '[[ -n "$TMP"  ]] && rm -f "$TMP";  [[ -n "$TMP2" ]] && rm -f "$TMP2"; exit' EXIT

# 1. Load order in the system main.lua --------------------------------------
apply_main_lua() {
    if [[ ! -f "$MAIN_LUA" ]]; then
        echo "skip: $MAIN_LUA not found (is hypryou installed?)"
        return
    fi

    local user_line gen_line
    user_line="$(grep -nF "$USER_LINE" "$MAIN_LUA" | head -n1 | cut -d: -f1 || true)"
    gen_line="$(grep -nF "$GEN_LINE" "$MAIN_LUA" | head -n1 | cut -d: -f1 || true)"

    if [[ -n "$user_line" && -n "$gen_line" && "$user_line" -gt "$gen_line" ]]; then
        echo "already applied: main.lua already loads hyprland.lua last"
        return
    fi

    echo "fixing main.lua load order (generated first, user config last)"
    TMP="$(mktemp)"
    awk -v u="$USER_LINE" -v g="$GEN_LINE" -v c="$COMMENT" '
        index($0, u) > 0 { next }
        index($0, g) > 0 { next }
        { print }
        END { print g; print c; print u }
    ' "$MAIN_LUA" > "$TMP"

    # Back up the stock file once, immediately before the first write.
    if [[ ! -f "$MAIN_BACKUP" ]]; then
        echo "backing up $MAIN_LUA -> $MAIN_BACKUP"
        sudo install -d -m 755 "$(dirname "$MAIN_BACKUP")"
        sudo cp -a "$MAIN_LUA" "$MAIN_BACKUP"
    fi

    sudo install -m 644 "$TMP" "$MAIN_LUA"
    rm -f "$TMP"
    TMP=""
}

# 2. ly restart policy ------------------------------------------------------
apply_ly_restart() {
    if [[ ! -f "$LY_DROPIN" ]]; then
        echo "creating $LY_DROPIN"
        sudo install -d -m 755 "$LY_DROPIN_DIR"
        printf '[Service]\nRestart=always\nRestartSec=1\n' | sudo tee "$LY_DROPIN" >/dev/null
        sudo systemctl daemon-reload
        return
    fi

    # Section-aware transform of the first [Service] section only:
    #   - a key present with the wrong value is rewritten in place
    #   - a key absent from [Service] is appended under it
    #   - a missing [Service] section is created
    # Keys in other sections are ignored and left untouched.
    TMP="$(mktemp)"
    awk '
        NR == FNR {
            if (!seen_service && $0 ~ /^\[Service\][[:space:]]*$/) {
                seen_service = 1
                pre_in_service = 1
            } else if ($0 ~ /^\[[^]]*\][[:space:]]*$/) {
                pre_in_service = 0
            } else if (pre_in_service) {
                if ($0 ~ /^[[:space:]]*Restart[[:space:]]*=/)    rs_present = 1
                if ($0 ~ /^[[:space:]]*RestartSec[[:space:]]*=/) rss_present = 1
            }
            next
        }
        {
            if (!started && $0 ~ /^\[Service\][[:space:]]*$/) {
                started = 1
                in_service = 1
                print
                if (!rs_present)  { print "Restart=always"; rs_present = 1 }
                if (!rss_present) { print "RestartSec=1";    rss_present = 1 }
                next
            }
            if ($0 ~ /^\[[^]]*\][[:space:]]*$/) in_service = 0
            if (in_service) {
                if ($0 ~ /^[[:space:]]*Restart[[:space:]]*=/)    { print "Restart=always"; next }
                if ($0 ~ /^[[:space:]]*RestartSec[[:space:]]*=/) { print "RestartSec=1";    next }
            }
            print
        }
        END {
            if (!seen_service) {
                print ""
                print "[Service]"
                print "Restart=always"
                print "RestartSec=1"
            }
        }
    ' "$LY_DROPIN" "$LY_DROPIN" > "$TMP"

    if cmp -s "$TMP" "$LY_DROPIN"; then
        echo "already applied: $LY_DROPIN"
    else
        echo "updating $LY_DROPIN (preserving other lines)"
        sudo install -m 644 "$TMP" "$LY_DROPIN"
        sudo systemctl daemon-reload
    fi
    rm -f "$TMP"
    TMP=""
}

# 3. GTK decoration layout --------------------------------------------------
apply_gtk_layout() {
    local file start end keyline
    for file in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        mkdir -p "$(dirname "$file")"
        if [[ ! -f "$file" ]]; then
            echo "creating $file with [Settings] and empty decoration layout"
            printf '[Settings]\ngtk-decoration-layout=:\n' > "$file"
            continue
        fi

        # Locate the FIRST [Settings] section and its end.
        start="$(grep -nE '^\[Settings\][[:space:]]*$' "$file" | head -n1 | cut -d: -f1 || true)"
        if [[ -z "$start" ]]; then
            echo "adding [Settings] section to $file"
            printf '\n[Settings]\ngtk-decoration-layout=:\n' >> "$file"
            continue
        fi
        end="$(awk -v s="$start" 'NR > s && /^\[[^]]*\][[:space:]]*$/ { print NR; exit }' "$file")"
        [[ -n "$end" ]] || end="$(awk 'END { print NR }' "$file")"

        # A decoration key inside the first [Settings] section (only).
        keyline="$(sed -n "${start},${end}p" "$file" | grep -nE '^[[:space:]]*gtk-decoration-layout=' | head -n1 | cut -d: -f1 || true)"

        if [[ -n "$keyline" ]]; then
            keyline=$(( start + keyline - 1 ))
            if sed -n "${keyline}p" "$file" | grep -qx 'gtk-decoration-layout=:'; then
                echo "already applied: $file"
            else
                echo "updating decoration layout in the first [Settings] in $file"
                sed -i "${keyline}s/^[[:space:]]*gtk-decoration-layout=.*/gtk-decoration-layout=:/" "$file"
            fi
        else
            echo "adding decoration layout to the first [Settings] in $file"
            sed -i "${start}s/^\[Settings\][[:space:]]*$/&\ngtk-decoration-layout=:/" "$file"
        fi
    done
}

# 4. Bar workspace buttons: reset theme button chrome ----------------------
# Adwaita's base `button` rule paints a background-image gradient and a
# box-shadow; HyprYou's SCSS only clears background-color/border, so every
# workspace button keeps a faint ring. Append an override to the compiled
# stylesheet's source and reload, since hypryou upgrades restore the file.
apply_bar_css() {
    if [[ ! -f "$BAR_SCSS" ]]; then
        echo "skip: $BAR_SCSS not found (is hypryou installed?)"
        return
    fi

    if grep -qF "$BAR_MARKER" "$BAR_SCSS"; then
        echo "already applied: bar workspace button CSS reset"
        return
    fi

    echo "patching $BAR_SCSS (reset theme button chrome on workspace buttons)"
    if [[ ! -f "$BAR_BACKUP" ]]; then
        echo "backing up $BAR_SCSS -> $BAR_BACKUP"
        sudo install -d -m 755 "$(dirname "$BAR_BACKUP")"
        sudo cp -a "$BAR_SCSS" "$BAR_BACKUP"
    fi

    TMP="$(mktemp)"
    {
        cat "$BAR_SCSS"
        printf '\n%s\n%s\n' "$BAR_MARKER" \
'window.bar .workspaces .workspace {
    background-image: none;
    box-shadow: none;
    outline: none;
}'
    } > "$TMP"
    sudo install -m 644 "$TMP" "$BAR_SCSS"
    rm -f "$TMP"
    TMP=""

    if command -v hypryouctl >/dev/null 2>&1; then
        if hypryouctl reload_css >/dev/null 2>&1; then
            echo "reloaded HyprYou CSS"
        else
            echo "note: CSS patched but reload failed; run 'hypryouctl reload_css' or relog"
        fi
    fi
}

apply_autostart() {
    local autostart="/usr/share/hypryou/configs/hyprland/autostart.lua"
    if [[ ! -f "$autostart" ]]; then
        echo "skip: $autostart not found (is hypryou installed?)"
        return
    fi

    # Idempotence: skip once both patches are in place.
    if grep -q '/usr/share/hypryou/hyprland/scripts/xdg.sh' "$autostart" \
       && ! grep -qE '^[[:space:]]*hl\.exec_cmd\("hypryou-start"\)' "$autostart"; then
        echo "already applied: xdg.sh path fixed and hypryou-start launch removed"
        return
    fi

    echo "fixing autostart.lua (xdg.sh path, and hypryou-start handover)"

    if ! sudo install -d -m 755 /var/backups; then
        echo "error: cannot create /var/backups" >&2
        return 1
    fi
    if [[ ! -f "$AUTOSTART_BACKUP" ]]; then
        echo "backing up $autostart -> $AUTOSTART_BACKUP"
        sudo cp -a "$autostart" "$AUTOSTART_BACKUP"
    fi

    TMP="$(mktemp)"
    # 1. xdg.sh moved from /usr/lib/hypryou/assets/ to /usr/share/hypryou/hyprland/scripts/.
    #    With the stale path it never ran, so the portal processes kept the display-less
    #    environment inherited from a TTY login and the yazi file chooser stayed broken.
    sed -e 's#/usr/lib/hypryou/assets/hyprland/scripts/xdg\.sh#/usr/share/hypryou/hyprland/scripts/xdg.sh#' \
        "$autostart" | grep -vE '^[[:space:]]*hl\.exec_cmd\("hypryou-start"\)' >"$TMP"

    # 2. Drop the bare hypryou-start launch. hypryou is single-instance, so this raced the
    #    supervised systemd unit: the unit lost the lock, gave up after ~6s, showed the
    #    crash dialog, and Restart=always repeated that every ~9s indefinitely. hypryou is
    #    now started only by ~/.config/systemd/user/hypryou.service, handed over by
    #    ~/.local/bin/hypryou-session-start.sh from ~/.config/hypryou/hyprland.lua.
    #
    #    The note explaining that goes *inside* the handler, immediately before the trailing
    #    `end)`, so a reader sees it where the missing call used to be.
    local note
    note=$'\n    -- hypryou-start is deliberately NOT launched here. hypryou is single-instance,\n    -- so launching it bare raced the supervised systemd unit, which lost the lock,\n    -- gave up, showed the crash dialog, and (Restart=always) repeated every ~9s. It is\n    -- started only by ~/.config/systemd/user/hypryou.service, handed over by\n    -- ~/.local/bin/hypryou-session-start.sh wired from ~/.config/hypryou/hyprland.lua.\n'

    TMP2="$(mktemp)"
    awk -v note="$note" '{ if ($0 ~ /^end\)/) printf "%s", note; print }' "$TMP" >"$TMP2"
    mv -f "$TMP2" "$TMP"
    TMP2=""

    if luac -p "$TMP" 2>/dev/null; then
        sudo install -m 644 "$TMP" "$autostart"
        rm -f "$TMP"
        TMP=""
        echo "patched $autostart"
    else
        echo "error: patched autostart.lua failed luac -p, leaving original in place" >&2
        rm -f "$TMP"
        TMP=""
        return 1
    fi
}

echo "==> HyprYou post-install"
apply_main_lua
apply_ly_restart
apply_gtk_layout
apply_bar_css
apply_autostart
echo "==> Done."
