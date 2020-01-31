# Tunic

Install Linux on Windows without a Live USB.

The goal is a program that can install Linux on an existing Windows machine without need of a Live USB or making firmware/BIOS changes.

## Status

This project is a pre-release.
There is a lot of work left to do in terms of features and quality.

### Requirements

* Windows 10, 64 bit
* Single drive hosting the C: volume
* UEFI  (supports secure boot)
* At least 4 GB RAM
* At least 15 GB of free disk space on C:
* Administrator user permissions
* Internet access
* AC Wall Power

### Limitations

* Currently, Tunic only installs [Linux Mint 64 bit](https://blog.linuxmint.com/?p=3832).
* We are working on testing Windows 7 and 8, MBR, and support for other Debian/Ubuntu based Linux distros.
* Error handling needs improvement.

### What Tunic Does

1. Asks all questions at beginning
1. Offers full disk overwrite or dual boot arrangement.
1. If dual boot, shrink C: volume to make space for Linux.  May require reboot.
1. Download the Linux .iso file
1. Install Grub with Secure Boot support
1. Reboot and run the Ubiquity installer, automated
1. Reboot into Linux!

## Getting Started

### Preparation

Backup your data!

Before you start, make sure to backup up your entire disk(s).
Tunic does not assist with full disk backup.
Read disclaimer for more information.

No, really.  Backup your data.

### Usage

1. Download and run the latest .exe file from releases.
1. Answer questions.
1. Let it run.  It may take a long time.
1. Enjoy your new Linux OS!

## More information

See the docs directory for more information.

## Legal Stuff

### License

Copyright (c) 2020 Michael Slattery.  See commit history for list of other authors.

Distributed under the [GNU General Public License, version 3](https://www.gnu.org/licenses/gpl-3.0.html).

### Disclaimer

This software could inadvertantly and permanently destroy all data, leave a computer unbootable,
or otherwise leave a computer in an undesirable state.
This software comes as-is with absolutely no warranty.
In no event shall shall the authors be held liable for damages arising out of use of this software.
Read sections [15, 16, and 17](https://www.gnu.org/licenses/gpl-3.0.html#section15) of the GNU GPL version 3 license for more information.

