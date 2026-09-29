#!/usr/bin/env bash
#
# hypryou-post-install.sh
#
# Idempotent post-install / post-upgrade fixes for HyprYou (AUR: hypryou,
# hypryou-utils). hypryou upgrades restore the stock files, so run this again
# after every install or upgrade.
#
#   1. main.lua load order: load the user config last, after the generated one.
#   2. ly restart policy: keep the tty2 session alive after it exits.
#   3. GTK decoration layout: hide window buttons (empty layout).
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
LY_DROPIN_DIR="/etc/systemd/system/ly@tty2.service.d"
LY_DROPIN="${LY_DROPIN_DIR}/restart.conf"

USER_LINE='dofileOrCreate(os.getenv("HOME") .. "/.config/hypryou/hyprland.lua")'
GEN_LINE='dofileOrCreate(os.getenv("HOME") .. "/.config/hypryou/hyprland_generated.lua")'
COMMENT='-- Load the user config last so its unbind/bind calls win over the settings file.'

TMP=""
trap 'if [[ -n "$TMP" ]]; then rm -f "$TMP"; fi' EXIT

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

echo "==> HyprYou post-install"
apply_main_lua
apply_ly_restart
apply_gtk_layout
echo "==> Done."
