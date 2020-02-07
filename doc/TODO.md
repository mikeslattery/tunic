# Roadmap and TODOs

## Goals

* As easily and as robustly as possible, convert a standard Windows system
to dual boot with Linux without the need for a USB drive or firmware changes.
* Linux to be configured the same as Windows with similar applications.

## Technology

This is subject to change over time.

* Runs from Windows as exe file
* Written in Powershell and Python
* YAML configured

## Versions

### MVP

* Opinionated, limited, non-robust
* Requires: Powershell 1.0, Win 10 64bit, Single OS(win), single disk, C:, EFI
* Installs: Dual boot, Linux Mint 64bit w/Cinnamon
* Auto-Configure basics: user account, locale, lang
* No support: XP/7/8, MBR, Bitlocker, AD, 32bit, LVM
* Run as exe as administrator (ps2exe)

### MVP 2

* Add Support: Other Ubuntu variants, Full disk, MBR convertion
* Port config: wifi passwords, locale, Chrome/Firefox settings
* Limited efi backup/restore/revert functionality.  before.cfg, after.cfg

### 1.0

* Add support: Windows 7/8, MBR, flexible partitioning, 32 bit Windows, Bitlocker, Full disk
* Choice of several Debian/Ubuntu based distros
* Port settings and apps
* Plugins and flexible configuration to make it easy for others to help
* Buttons to go to web sites for help: google search, ubuntu support
* LVM and/or partition util?
* Programming Language change?
* Desktop icons: efi recover, OS in VM, reboot, browse files
* VirtualBox Linux host runs Windows partition w/sync protections.
* Reboot and continue without user intervention of password during install
* Keyboard layout preseed/import
* Tunic welcome app

## Other Possible Use Cases and sub-components

### Windows

* Import apps from Windows to OSS Windows
* Cleanup disk
* Install Linux in a VM
* Full convert from Windows to Linux
* Install existing Linux partition as VM
* Uninstall Linux dual boot
* Install WSL to partition.
* Run Linux in file on ntfs/ext4 loopback

### Windows and Linux

* EFI/Grub/boot menu restore or repair
* Make persistent USB
* Shrink/Split/merge/move partitions.
* Shrink windows/expand Linux
* Backup/Restore MBR/EFI
* Make Live USB
* Live USB with multiple distros

### Linux

* Convert Windows Partition to VM and delete from grub/nvram
* Distro hop switcher
* Import settings/apps from Windows to Linux
* Remove Windows
* Install Windows after Linux
* Install another Linux distro over current.
* Convert to LVM
* Fast EFI boot (fwbootmgr -> Linux kernel w/ ext4 efi driver)
* Decimate Windows.  Delete all except user files, defrag.

### Far Future
* Allow secure boot.  Detect if supportable.
* Support for: Windows Vista/XP, 32bit w/MBR, MBR
* AD domain login
* Fully remove Windows with option to convert to VM
* Minimal distro default if <=2GB.
* Non-debian distros.
* Distro switcher.  Add multiple distros into menu.
* Assist with backup
* Warnings/help for known problematic hardware
* MacOS to Elementary OS

## TODOs

### Development

#### Short-term Challenges
* Install grub from single source (ubuntu 18.04 + grub-for-windows)
* Re-enable swap.  fix caption

### Medium term challenges
* Auto-Resume from reboot
* Disable swap without reboot

#### Long Term Challenges
* Install powershell if not available
* Help with backup/clone

#### Testing setup
* Vagrant
* Linux host.  Possible WSL/Cygwin support.
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
* grub syntax checker

### User Warnings and Errors

#### Checks

* Administrator
* enough space
* 64 bit
* Not on battery
* EFI/GPT/MBR, no secure boot
* Windows 10
* Powershell libs available
* Command line apps available
* Bitlocker
* Compatibility (some day)

#### Warnings

* Backup
* Upgrade firmware
* Disable secure boot
* Might brick your machine
* Limited support

#### Uninstallers

* grub.cfg + initrd.lz - Undo installation (up to this point)

#### Compatibility Warnings

* NVidia

## Support and Testing

### Manual Testing

* MBR vs EFI
* Test on Windows 7
* Bitlocker
* Secure boot

### Automated Testing
* VirtualBox in VirtualBox. Nested VBox only supports 32bit OSes
* Download VMs from Microsoft
* Install apps in Windows
* Cache file downloads (option)
* Scenarios: MBR/EFI, Win 7/10
* Scripted.
* Limit phases.  Use snapshots for start phase.

## Basic Flow
1. Clean
2. Create new parition
3. Copy ISO to partition (not including MBR)
4. Modify ISO partition to include seed files
5. Copy grub files to efi partition
6. Reboot to Linux

