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
* git clone install

### MVP - 0.1
* Set of individual PowerShell scripts.
* Opinionated, limited, non-robust
* Requires: Powershell 1.0, Win 10 64bit, Single OS(win), Single C:, EFI, no secure boot
* Installs: Virtualbox, dual boot, Linux Mint 64bit w/cinnamon
* Configure basics: user account, locale, lang
* Mounted C: drive in LInux
* Install using DownloadString('github..ps1') | iex

### 0.2
* Port iconds: wifi passwords. Documents, Chrome/Firefox settings
* Desktop icons: Reboot to Windows/Linux
* Limited efi backup, restore, revert functionality.  before.cfg, after.cfg

### 1.0
* GUI
* Single .exe elevated available from github releases
* Flexible.  Many entry-points and exit points.  Launch other utilities for help.
* Added support: Windows Vista/7/8/10, flexible partitioning, 32 bit Windows/Linux
* Convert to GPT or support MBR
* VirtualBox Linux host runs Windows partition w/sync protections.
* Port system settings
* Port known apps
* Plugins and flexible configuration to make it easy for others to help
* Choice of several Debian/Ubuntu based distros
* Buttons to go to web sites: google search, ubuntu support
* LVM and/or partition util
* Language change?
* Get rid of dependency on Virtualbox.  Rebuild iso with unattended install script(s).

### Far Future
* Windows XP and 32bit support
* Reboots and continue without password
* AD domain login
* Minimal distro default if <=2GB.
* Non-debian distros.
* Distro switcher
* Assist with backup
* Warnings/help for known problematic hardware
* MacOS to Elementary OS
* Grub auto-recover in case windows overwrites efi
* BIOS autoconfig. e.g. Dell client configuration utility

## Other Possible Use Cases and sub-components
* Backup/Restore MBR/EFI
* Cleanup disk
* Shrink/Split/merge/move partitions
* Install Linux in a VM
* Convert Windows Partition to VM and delete
* Make Live USB
* Uninstall Linux dual boot
* Distro hop switcher
* Import settings/apps from Windows to Linux
* Full convert from Windows to Linux
* EFI/Grub/boot menu recovery

## TODOs

### Development

#### Big Short-term Challenges
* EFI and boot menu
* Unattended Linux install in a VM
* Auto-Resume from reboot
* Help with backup/clone

#### Short Term
* Disable fast boot
* Disable Hyper-V
* Install powerwhell 1.0 if not available
* Install Virtualbox w/o choco (but use choco if's installed)

#### Testing setup
* Linux host.  Possible WSL/Cygwin support.
* Download MS Windows testing VM.  Unzip and import.
* Create linked clone.  Install all the things.
* Install: mbr2gpt, sshd, guest additions,
* modifyvm for efi boot. disable secure boot.
* Download ISO and place in a cache directory.

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

### User Warnings and Errors

#### Checks

* Administrator
* enough space
* 64 bit
* Not on battery
* Virtualization enabled
* EFI/GPT/MBR, no secure boot
* Windows 10
* Powershell libs available
* Command line apps available
* Hyper V not enabled
* Choco installed
* Virtualbox installed
* Compatibility (some day)

#### Warnings

* Backup
* Upgrade firmware
* Disable secure boot
* Might brick your machine
* Limited support

#### Compatibility Warnings

* NVidia

## Support and Testing

### Manual Testing

* MBR vs EFI
* Test on Windows 7

### Automated Testing
* VirtualBox in VirtualBox. Nested VBox only supports 32bit OSes
* Download VMs from Microsoft
* Install apps in Windows
* Cache file downloads (option)
* Scenarios: MBR/EFI, Win 7/10
* Scripted.
* Limit phases.  Use snapshots for start phase.

## Impossible?
* Switch to/from MBR/GPT
* Disable secure boot
* Download and run c0firmware updater
* Enable virtualization

## Basic Flow
1. Clean
2. Create new parition
3. Copy ISO to partition (not including MBR)
4. Modify ISO partition to include seed files
5. Copy grub files to efi partition
6. Reboot to Linux

