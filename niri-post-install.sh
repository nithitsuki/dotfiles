#!/usr/bin/env bash
#
# niri-post-install.sh — display-manager handoff (ly -> SDDM) + greeter theme.
#
# Run as root after every install or upgrade:
#
#   1. SDDM on: enable sddm.service (iNiR's greeter; re-themed on wallpaper change).
#   2. ly off: disable every ly@ttyN.service instance left from the old setup
#      and restore that tty's getty, so nothing fights SDDM at boot.
#   3. Theme pin: /etc/sddm.conf.d drop-in forcing Current=ii-pixel, applied
#      only when the iNiR theme is actually installed.
#   4. Sanity: graphical.target default + niri-session desktop file present.
#
# Usage: sudo ./niri-post-install.sh
#

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run as root (sudo ./niri-post-install.sh)."
    exit 1
fi

SDDM_DROPIN_DIR="/etc/sddm.conf.d"
# NOTE: the "zz-" prefix sorts after kde_settings.conf (KDE rewrites that file
# and it otherwise wins over our pin) and after iNiR's own 99-inir-theme.conf.
SDDM_DROPIN="${SDDM_DROPIN_DIR}/zz-inir-theme.conf"
SDDM_BACKUP="/var/backups/sddm-zz-inir-theme.conf.orig"
# Predecessor name used before kde_settings.conf was found to override the pin.
SDDM_DROPIN_OLD="${SDDM_DROPIN_DIR}/10-inir-theme.conf"

# 1. SDDM on ---------------------------------------------------------------
if [[ -f /usr/lib/systemd/system/sddm.service ]]; then
    echo "enabling sddm.service"
    systemctl enable sddm.service
else
    echo "skip: sddm.service unit not found (is sddm installed?)"
fi

# 2. ly off -----------------------------------------------------------------
mapfile -t LY_WANTS < <(
    find /etc/systemd/system/multi-user.target.wants -maxdepth 1 -name 'ly@*.service' 2>/dev/null || true
)
if [[ ${#LY_WANTS[@]} -eq 0 ]]; then
    echo "already applied: no ly@ instances wanted at boot"
else
    for want in "${LY_WANTS[@]}"; do
        inst="$(basename "$want")"
        echo "disabling $inst"
        systemctl disable "$inst"
        # ly's installer disables getty on the same tty; give it back.
        # NOTE: no pipefail-sensitive pipeline here — `is-enabled` exits 1
        # when disabled, so compare its output instead of grepping it.
        if [[ "$inst" =~ ly@(.+)\.service ]]; then
            tty="${BASH_REMATCH[1]}"
            getty_state="$(systemctl is-enabled "getty@${tty}.service" 2>/dev/null || true)"
            if [[ "$getty_state" == "disabled" ]]; then
                echo "restoring getty@${tty}.service"
                systemctl enable "getty@${tty}.service"
            fi
        fi
    done
fi

# 3. Theme pin ---------------------------------------------------------------
# Drop-in first (zz- prefix wins over kde_settings.conf and iNiR's 99- file).
if [[ -d /usr/share/sddm/themes/ii-pixel ]]; then
    if [[ -f "$SDDM_DROPIN" ]] && grep -q '^Current=ii-pixel$' "$SDDM_DROPIN"; then
        echo "already applied: SDDM theme pinned to ii-pixel"
    else
        echo "pinning SDDM theme to ii-pixel ($SDDM_DROPIN)"
        if [[ -f "$SDDM_DROPIN" && ! -f "$SDDM_BACKUP" ]]; then
            echo "backing up $SDDM_DROPIN -> $SDDM_BACKUP"
            install -d -m 755 "$(dirname "$SDDM_BACKUP")"
            cp -a "$SDDM_DROPIN" "$SDDM_BACKUP"
        fi
        install -d -m 755 "$SDDM_DROPIN_DIR"
        printf '[Theme]\nCurrent=ii-pixel\n' > "$SDDM_DROPIN"
        chmod 644 "$SDDM_DROPIN"
    fi
    # Remove the predecessor drop-in name so only one pin file remains.
    if [[ -f "$SDDM_DROPIN_OLD" ]]; then
        echo "removing predecessor $SDDM_DROPIN_OLD"
        rm -f "$SDDM_DROPIN_OLD"
    fi
    # kde_settings.conf sorts after numbered drop-ins and otherwise overrides
    # the pin (e.g. Current=MacSequoia-Dark). Align it when present.
    if [[ -f "$SDDM_DROPIN_DIR/kde_settings.conf" ]] && grep -q '^Current=' "$SDDM_DROPIN_DIR/kde_settings.conf"; then
        if grep -q '^Current=ii-pixel$' "$SDDM_DROPIN_DIR/kde_settings.conf"; then
            echo "already applied: kde_settings.conf theme is ii-pixel"
        else
            echo "aligning kde_settings.conf theme to ii-pixel"
            if [[ ! -f /var/backups/sddm-kde_settings.conf.orig ]]; then
                install -d -m 755 /var/backups
                cp -a "$SDDM_DROPIN_DIR/kde_settings.conf" /var/backups/sddm-kde_settings.conf.orig
            fi
            sed -i 's/^Current=.*/Current=ii-pixel/' "$SDDM_DROPIN_DIR/kde_settings.conf"
        fi
    fi
else
    echo "skip: ii-pixel theme not installed (run iNiR setup extras first)"
fi

# 4. Sanity ------------------------------------------------------------------
if [[ "$(systemctl get-default)" != "graphical.target" ]]; then
    echo "setting default target to graphical.target"
    systemctl set-default graphical.target
fi

if [[ -f /usr/share/wayland-sessions/niri.desktop ]]; then
    echo "ok: niri.desktop session file present"
else
    echo "WARN: /usr/share/wayland-sessions/niri.desktop missing (reinstall niri?)"
fi

echo "done."
