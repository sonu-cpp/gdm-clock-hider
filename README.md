# Hide Clock on GDM

A small script to hide the date/time clock from the GNOME GDM login screen.

This works by installing a small GNOME Shell extension specifically for the GDM session. The install script backs up the existing GDM dconf configuration before making changes. 

## What it does

- Hides the clock/date menu on the GDM login screen.
- Creates a small system-wide GNOME Shell extension.
- Detects your installed GNOME Shell major version and uses the appropriate extension format.
- Backs up `/etc/dconf/db/gdm.d/` before changing it.
- Keeps any existing GDM extensions in the enabled list.
- Restarts GDM after installation.

> **Note:** Restarting GDM will end your current graphical session. Save your work before running the installer.

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

After it finishes, log out completely or reboot and check the GDM login screen.

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
