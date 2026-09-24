#!/usr/bin/env bash
# uninstall_hide_gdm_clock.sh
#
# Undoes install_hide_gdm_clock.sh: removes the extension directory and
# restores /etc/dconf/db/gdm.d/ from the backup made at install time.


set -euo pipefail

UUID="hide-clock-gdm@local"
EXT_DIR="/usr/share/gnome-shell/extensions/${UUID}"
DCONF_GDM_DIR="/etc/dconf/db/gdm.d"
BACKUP_DIR="/root/gdm-clock-ext-backup"
LATEST_FILE="${BACKUP_DIR}/latest-dconf-backup.txt"

if [[ $EUID -ne 0 ]]; then
    echo "Error: run this script as root (sudo)." >&2
    exit 1
fi

if [[ $# -ge 1 ]]; then
    BACKUP_TARBALL="$1"
elif [[ -f "$LATEST_FILE" ]]; then
    BACKUP_TARBALL="$(cat "$LATEST_FILE")"
else
    echo "Error: no backup tarball given and none recorded." >&2
    echo "Look in $BACKUP_DIR for dconf-gdm-d.bak-*.tar.gz and pass it as an argument." >&2
    exit 1
fi

if [[ ! -f "$BACKUP_TARBALL" ]]; then
    echo "Error: backup file not found: $BACKUP_TARBALL" >&2
    exit 1
fi

echo "Removing extension directory: $EXT_DIR"
rm -rf "$EXT_DIR"

echo "Restoring $DCONF_GDM_DIR from $BACKUP_TARBALL"
rm -rf "$DCONF_GDM_DIR"
tar -xzf "$BACKUP_TARBALL" -C "$(dirname "$DCONF_GDM_DIR")"

if ! command -v dconf >/dev/null 2>&1; then
    echo "Warning: dconf command not found, could not run 'dconf update'." >&2
else
    dconf update
    echo "dconf database updated."
fi

echo "Restarting GDM..."
systemctl restart gdm

