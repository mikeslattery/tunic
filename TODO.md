# Roadmap and TODOs

## Goal

As easily and as robustly as possible, convert a standard Windows system
to dual boot with Linux.
Linux configured the same as Windows with similar applications.

## Technology

This is subject to change over time.

* Runs from Windows
* No need for USB drive
* Post-install Linux script also written in Powershell
* YAML configured
* Windows Boot Manager (instead of grub)
* Powershell

## Roadmap

### PoC
* Limited Scripts to install Linux without any manual steps

### MVP - 0.1
* Set of individual PowerShell scripts.
* git clone install
* Opinionated, limited, non-robust
* Requires: Powershell 1.0, Win 7/10 64bit, Single OS(win), Single C:, EFI, no secure boot
* Installs: Virtualbox, dual boot, Linux Mint 64bit w/cinnamon
* Configure basics: user account, locale, lang
* Full revert.  before.txt, after.txt
* /mnt/c

### 0.2
* wifi passwords. Documents, Chrome/Firefox settings
* VirtualBox run Windows partition included w/sync protections.
* Convert to GPT, when possible.
* Add: Ubuntu

### 1.0
* GUI
* Single .exe elevated available from github releases
* Flexible.  Many entry-points and exit points.  Launch other utilities for help.
* Added support: Windows Vista/7/8/10, MBR, flexible partitioning, 32 bit Windows/Linux
* Port system settings
* Port known apps
* Plugins and flexible configuration to make it easy for others to help
* Choice of several Debian/Ubuntu based distros
* Buttons to go web sites: google search, ubuntu support
* Language?

### Far Future
* Windows XP support
* Non-debian distros
* Distro switcher
* Assist with backup
* Warnings for known problematic hardware
* MacOS to Linux

## TODOs

### Short Term
* Disable fast boot
* Disable Hyper-V
* Install powerwhell 1.0 if not available
* Install Virtualbox w/o choco (but use choco if it is)

### Big Short-term Challenges

* EFI
* Unattended Linux install in a VM
* Auto-Resume from reboot
* Help with backup/clone

### Documentation
* Plugins how-to
* contribute.md
* support
* how to write a ticket: .log file

#### Contributing doc
* Work in branch
* Suggest: ticket first with "thumbs up" from me.
* Follow standards

#### standards
* .editorconfig
* lint check

### Checks

* Administrator
* enough space
* Virtualization enabled
* EFI/GPT/MBR, secure boot
* Windows 10
* Powershell libs available
* Command line apps available
* Hyper V not installed
* Choco installed
* Virtualbox installed
* Compatibility (some day)

### Warnings

* Backup
* Upgrade firmware
* Disable secure boot
* Might brick your machine
* Limited support

### Compatibility Warnings

* NVidia

### Testing

* MBR vs EFI
* Test on Windows XP
* Partially automated.  Windows with script that starts on boot

## Misc

* Powersheme import/export with powercfg.exe
* Cloners: ODIN, Partition-Saving, Clonedisk
* 32bit support

### Impossible?
* Switch to legacy boot
* Disable secure boot
* Enable virtualization

