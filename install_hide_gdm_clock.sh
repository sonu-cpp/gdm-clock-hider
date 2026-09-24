#!/usr/bin/env bash
# install_hide_gdm_clock.sh
#
# GNOME Shell's theme CSS cannot hide widgets (no display:none support),
# so hiding the GDM clock has to be done in code: this installs a small
# system-wide GNOME Shell extension that runs during the login screen
# ("session-modes": ["gdm"]) and hides the date/time menu.
#
# Backs up /etc/dconf/db/gdm.d/ before touching it, so
# uninstall_hide_gdm_clock.sh can restore GDM's configuration exactly.
#
# Run as root. Restarts GDM at the end.
# Recommended: run from a TTY (Ctrl+Alt+F3), and have a live USB on
# hand just in case, per general GDM-extension caveats.

set -euo pipefail

UUID="hide-clock-gdm@local"
EXT_DIR="/usr/share/gnome-shell/extensions/${UUID}"
DCONF_GDM_DIR="/etc/dconf/db/gdm.d"
BACKUP_DIR="/root/gdm-clock-ext-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Error: run this script as root (sudo)." >&2
    exit 1
fi

if ! command -v gnome-shell >/dev/null 2>&1; then
    echo "Error: gnome-shell not found." >&2
    exit 1
fi

if ! command -v dconf >/dev/null 2>&1; then
    echo "Error: dconf command not found (package: dconf-cli)." >&2
    exit 1
fi

SHELL_VERSION_RAW="$(gnome-shell --version | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)"
SHELL_MAJOR="${SHELL_VERSION_RAW%%.*}"
echo "Detected GNOME Shell version: ${SHELL_VERSION_RAW:-unknown} (major: ${SHELL_MAJOR:-unknown})"

if [[ -z "${SHELL_MAJOR:-}" ]]; then
    echo "Error: could not determine GNOME Shell major version." >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# Back up an existing copy of our own extension dir, if one is already there
if [[ -d "$EXT_DIR" ]]; then
    cp -a "$EXT_DIR" "${BACKUP_DIR}/ext-dir.bak-${TIMESTAMP}"
    echo "Backed up existing extension dir to ${BACKUP_DIR}/ext-dir.bak-${TIMESTAMP}"
fi

# Back up the whole gdm dconf db directory so uninstall can restore it exactly
mkdir -p "$DCONF_GDM_DIR"
DCONF_BACKUP="${BACKUP_DIR}/dconf-gdm-d.bak-${TIMESTAMP}.tar.gz"
tar -czf "$DCONF_BACKUP" -C "$(dirname "$DCONF_GDM_DIR")" "$(basename "$DCONF_GDM_DIR")"
echo "$DCONF_BACKUP" > "${BACKUP_DIR}/latest-dconf-backup.txt"
echo "Backed up $DCONF_GDM_DIR to $DCONF_BACKUP"

mkdir -p "$EXT_DIR"

cat > "${EXT_DIR}/metadata.json" <<EOF
{
    "uuid": "${UUID}",
    "name": "Hide GDM Clock",
    "description": "Hides the date/time indicator on the GDM login screen.",
    "shell-version": [ "${SHELL_MAJOR}" ],
    "session-modes": [ "gdm" ]
}
EOF

if [[ "$SHELL_MAJOR" -ge 45 ]]; then
    # GNOME 45+ uses ES modules and a class-based extension export
    cat > "${EXT_DIR}/extension.js" <<'EOF'
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class HideClockExtension extends Extension {
    enable() {
        this._dateMenu = Main.panel.statusArea.dateMenu;
        if (this._dateMenu)
            this._dateMenu.hide();
    }

    disable() {
        if (this._dateMenu) {
            this._dateMenu.show();
            this._dateMenu = null;
        }
    }
}
EOF
else
    # Pre-45 legacy extension format
    cat > "${EXT_DIR}/extension.js" <<'EOF'
const Main = imports.ui.main;

let _dateMenu = null;

function init() {
}

function enable() {
    _dateMenu = Main.panel.statusArea.dateMenu;
    if (_dateMenu)
        _dateMenu.hide();
}

function disable() {
    if (_dateMenu) {
        _dateMenu.show();
        _dateMenu = null;
    }
}
EOF
fi

echo "Extension files installed at $EXT_DIR"

# Make sure the extension is enabled for the gdm user. Some distros/GDM
# builds enable session-modes:["gdm"] extensions automatically; others
# need it listed explicitly. We add our uuid to whatever
# enabled-extensions list already exists for gdm, rather than
# overwriting it, so any extension already enabled there (e.g. from a
# theming tool) keeps working.
EXISTING_FILE=""
for f in "$DCONF_GDM_DIR"/*; do
    [[ -f "$f" ]] || continue
    if grep -q 'enabled-extensions' "$f" 2>/dev/null; then
        EXISTING_FILE="$f"
        break
    fi
done

TARGET_FILE="${EXISTING_FILE:-${DCONF_GDM_DIR}/95-hide-clock-gdm}"

if [[ -n "$EXISTING_FILE" ]]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 not found, needed to safely edit $TARGET_FILE." >&2
        echo "Add '${UUID}' to the enabled-extensions list in $TARGET_FILE manually, then run: dconf update" >&2
        exit 1
    fi
    python3 - "$TARGET_FILE" "$UUID" <<'PYEOF'
import re
import sys

path, uuid = sys.argv[1], sys.argv[2]
with open(path) as fh:
    content = fh.read()

m = re.search(r"enabled-extensions\s*=\s*\[(.*?)\]", content)
if m:
    items = [i.strip().strip("'\"") for i in m.group(1).split(",") if i.strip()]
    if uuid not in items:
        items.append(uuid)
    new_list = "[" + ", ".join(f"'{i}'" for i in items) + "]"
    content = content[:m.start()] + f"enabled-extensions={new_list}" + content[m.end():]
else:
    if "[org/gnome/shell]" not in content:
        content += "\n[org/gnome/shell]\n"
    content += f"enabled-extensions=['{uuid}']\n"

with open(path, "w") as fh:
    fh.write(content)
PYEOF
    echo "Added ${UUID} to the existing enabled-extensions list in $TARGET_FILE"
else
    cat > "$TARGET_FILE" <<EOF
[org/gnome/shell]
enabled-extensions=['${UUID}']
EOF
    echo "Created $TARGET_FILE enabling ${UUID}"
fi

dconf update
echo "dconf database updated."

echo "Restarting GDM..."
systemctl restart gdm

echo "Done. Log out fully (or reboot) and check the greeter."
echo "If the clock is still there, check the shell log for why the"
echo "extension didn't load:"
echo "  journalctl -b -u gdm | grep -i -E 'extension|hide-clock-gdm'"
