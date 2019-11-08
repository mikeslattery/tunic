# Roadmap and TODOs

## Goal

As easily and as robustly as possible, convert a standard Windows install
into a dual boot system with Linux.
Linux is configured the same as Windws with similar applications.

## Technology

* Powershell
* Runs from Windows
* No need for USB drive
* Post-install Linux script also written in Powershell
* YAML configured

## Roadmap

### MVP - 0.1
* Set of individual PowerShell scripts.
* git clone install
* Opinionated and limited
* Requires: Win 10, Single C:
* Only supports: Virtualbox, dual boot, Linux Mint w/cinnamon
* Several separarate scripts
* Configure basics: user account, wifi, locale

### 1.0
* GUI
* Single .exe elevated available from github releases
* Flexible.  Many entry-points and exit points.  Launch other utilities for help.
* Port many system settings
* Port known apps
* Plugins and flexible configuration to make it easy for others to help
* Choice of several Debian and Ubuntu based distros

## TODOs

### Misc
* Disable fast boot

### Documentation
* Plugins how-to
* contribute.md
* support
* how to write a ticket: .log file

### Big Challenges
* EFI
* Unattended Linux install in a VM
* Auto-Resume from reboot
* Help with backup/clone

### Impossible?
* Switch to legacy boot?
* Disable secure boot
* Enable virtualization

### Warnings
* Backup
* Upgrade firmware

### Checks

* enough space
* EFI/GPT/MBR
* Virtualization enabled
* Windows 10
* Powershell libs installed
* Hyper V instlled
* Choco installed
* Virtualbox installed
* secure boot enabled

## Misc

* Powersheme import/export with powercfg.exe
* Cloners: ODIN, Partition-Saving, Clonedisk
