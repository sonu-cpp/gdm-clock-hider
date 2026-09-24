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


This is also the command suggested by the installer for checking why the extension may not have loaded. 

## A few things to keep in mind


GNOME/GDM changes between releases, so this script may need updates for future GNOME Shell versions.

If you are experimenting with GDM theming or other GNOME Shell extensions, check for conflicts if something stops working after installation.
