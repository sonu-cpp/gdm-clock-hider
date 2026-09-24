# Hide Clock on GDM

A small script to hide the date/time clock from the GNOME GDM login screen.

This works by installing a small GNOME Shell extension specifically for the GDM session. The install script also backs up the existing GDM dconf configuration before making changes. fileciteturn0file0L4-L12

## What it does

- Hides the clock/date menu on the GDM login screen.
- Creates a small system-wide GNOME Shell extension.
- Detects your installed GNOME Shell major version and uses the appropriate extension format.
- Backs up `/etc/dconf/db/gdm.d/` before changing it.
- Keeps any existing GDM extensions in the enabled list.
- Restarts GDM after installation.

> **Note:** Restarting GDM will end your current graphical session. Save your work before running the installer.

## Files

```text
install_hide_gdm_clock.sh
uninstall_hide_gdm_clock.sh
```

`install_hide_gdm_clock.sh` installs and enables the extension.

`uninstall_hide_gdm_clock.sh` removes the extension and restores the GDM configuration from the backup created during installation. fileciteturn0file1L4-L9

## Requirements

You need:

- GNOME Shell / GDM
- `dconf`
- `dconf-cli`
- `sudo` access

The installer checks for `gnome-shell` and `dconf` before continuing. fileciteturn0file0L24-L36

## Installation

First, make the script executable:

```bash
chmod +x install_hide_gdm_clock.sh
```

Then run it as root:

```bash
sudo ./install_hide_gdm_clock.sh
```

That's it.

The script will create the extension, update the GDM dconf database, and restart GDM.

After it finishes, log out completely or reboot and check the GDM login screen. fileciteturn0file0L178-L187

### Recommended way to run it

Since this changes GDM and restarts the display manager, running it from a TTY is recommended:

```text
Ctrl + Alt + F3
```

Log in there and run the commands from the TTY.

It is also a good idea to have a live USB available in case GDM needs to be recovered.

## Uninstall / Restore

If you want the clock back, make the uninstall script executable:

```bash
chmod +x uninstall_hide_gdm_clock.sh
```

Then run:

```bash
sudo ./uninstall_hide_gdm_clock.sh
```

The uninstall script uses the latest backup automatically. It removes the extension, restores the previous GDM dconf directory, updates dconf, and restarts GDM. fileciteturn0file1L31-L63

### Using a specific backup

If you have more than one backup and want to restore a specific one:

```bash
sudo ./uninstall_hide_gdm_clock.sh /path/to/backup.tar.gz
```

Backups are stored under:

```text
/root/gdm-clock-ext-backup/
```

## If the clock is still showing

Check the GDM journal for extension-related errors:

```bash
journalctl -b -u gdm | grep -i -E 'extension|hide-clock-gdm'
```

This is also the command suggested by the installer for checking why the extension may not have loaded. fileciteturn0file0L184-L187

## Recovery

If GDM doesn't come back properly, you can switch to a TTY with:

```text
Ctrl + Alt + F3
```

and try the uninstall script:

```bash
sudo ./uninstall_hide_gdm_clock.sh
```

If that is not possible, the uninstall script includes a manual fallback:

1. Remove:

```text
/usr/share/gnome-shell/extensions/hide-clock-gdm@local/
```

2. Remove the GDM dconf entry that mentions:

```text
hide-clock-gdm@local
```

3. Run:

```bash
sudo dconf update
```

The uninstall script documents this as the last-resort recovery method. fileciteturn0file1L11-L17

## A few things to keep in mind

This modifies system files and the GDM configuration, so don't run it casually on a machine where you can't recover the graphical login.

GNOME/GDM changes between releases, so this script may need updates for future GNOME Shell versions.

If you are experimenting with GDM theming or other GNOME Shell extensions, check for conflicts if something stops working after installation.
