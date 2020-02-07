# Tunic

Install Linux over or alongside an existing Windows install, straight from Windows, without requiring to boot from external media like a flash drive or making BIOS configuration changes.

![Alt text](https://i.imgur.com/VOhRiGh.png) ![Alt text](https://i.imgur.com/YNNt4HZ.png) ![Alt text](https://i.imgur.com/9P8auhO.png)

### Requirements

* Windows 7, 8, 8.1, or 10, 64 bit
* Single drive hosting the C: volume
* UEFI  (supports secure boot)
* At least 4 GB RAM
* At least 15 GB of free disk space on C:
* Administrator user permissions
* Internet access
* AC Wall Power

### What Tunic Does

* Validates your system is compatible with Tunic.
* Asks all questions at beginning  (so you don't have to babysit the install).
* Offers to convert a MBR disk to UEFI.
* Offers full disk overwrite or dual boot arrangement.
* If dual boot, shrink C: volume to make space for Linux.
* Provides tools to assist with freeing up space for Linux.
* Provides Linux Mint, Ubuntu and most official Ubuntu flavors.
* Downloads the Linux .iso file for you.
* Installs Grub with Secure Boot support.
* Calculates Linux equivalent values for your Windows locale and user account.
* Reboots and runs the Ubiquity installer, automated.
* If custom install type choosen, will provide Ubuntu's Ubiquity partiton utility GUI.
* Reboots into your final installed Linux!

See the [TODO](doc/TODO.md) for ideas for future versions.

### Limitations

* Currently, Tunic only installs official flavors of Ubuntu and Linux Mint.
* We are working on testing Windows 7 and 8, MBR, and support for other Debian/Ubuntu based Linux distros.
* Error handling needs improvement.

### More information

See the [doc](doc) directory for more information.

## Getting Started

### Preparation

* Backup your data!

Before you start, make sure to backup up an image of your entire disk(s).
Tunic does not assist with full disk backup.
Read disclaimer for more information.

No, really.  Backup your data.

* Close all other running applications.

### Usage

1. Download and run the [latest executable file](https://github.com/mikeslattery/tunic/releases/latest/download/tunic.exe) from releases.
1. Answer questions.
1. Let it run.  It may take a long time.
1. Enjoy your new Linux OS!

## Legal Stuff

### License

Copyright (c) 2020 Michael Slattery.  See commit history for list of other authors.

Distributed under the [GNU General Public License, version 3](https://www.gnu.org/licenses/gpl-3.0.html).

### Disclaimer

This software could inadvertantly and permanently destroy all data, leave a computer unbootable,
or otherwise leave a computer in an undesirable state.
This software comes as-is with absolutely no warranty.
Read sections [15, 16, and 17](https://www.gnu.org/licenses/gpl-3.0.html#section15) of the GNU GPL version 3 license for more information.

