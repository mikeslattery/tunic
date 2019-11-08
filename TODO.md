# Roadmap and TODOs

## Goal

As easily and as robustly as possible, convert a standard Windows system
to dual boot with Linux.
Linux configured the same as Windows with similar applications.

## Technology

* Powershell
* Runs from Windows
* Windows Boot Manager (instead of grub)
* No need for USB drive
* Post-install Linux script also written in Powershell
* YAML configured

## Roadmap

### PoC
* Set of Scripts to install Linux without any manual steps

### MVP - 0.1
* Set of individual PowerShell scripts.
* git clone install
* Opinionated and limited
* Requires: Powershell 1.0, Win 10, Single C:, EFI
* Only supports: Virtualbox, dual boot, Linux Mint w/cinnamon
* Several separarate scripts
* Configure basics: user account, wifi, locale

### 1.0
* GUI
* Single .exe elevated available from github releases
* Flexible.  Many entry-points and exit points.  Launch other utilities for help.
* Only supported for Win 7, 10
* Port many system settings
* Port known apps
* Plugins and flexible configuration to make it easy for others to help
* Choice of several Debian and Ubuntu based distros

## TODOs

### Short Term
* Disable fast boot
* Disable Hyper-V
* Install powerwhell 1.0 if not available
* Install Virtualbox w/o choco (but use choco if it is)

### Big Challenges

* EFI
* Unattended Linux install in a VM
* Auto-Resume from reboot
* Help with backup/clone

### Documentation
* Plugins how-to
* contribute.md
* support
* how to write a ticket: .log file

### Checks

* enough space
* EFI/GPT/MBR
* Virtualization enabled
* Windows 10
* Powershell libs installed
* Hyper V installed
* Choco installed
* Virtualbox installed
* secure boot enabled

### Warnings

* Backup
* Upgrade firmware

### Testing

* Test on Windows XP
* Partially automated.  Windows with script that starts on boot

## Misc

* Powersheme import/export with powercfg.exe
* Cloners: ODIN, Partition-Saving, Clonedisk

### Impossible?
* Switch to legacy boot?
* Disable secure boot
* Enable virtualization

### Far Future

* MacOS to Linux

