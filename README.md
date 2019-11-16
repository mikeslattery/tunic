# tunic

Install Linux on Windows without a Live USB

The goal is a program or script that can install Linux on an existing Windows workstation without a LiveUSB or booting into Linux.

## Status

This project has just started and is simply a proof-of-concept.  It is of low quality.
Do not run any of the included scripts directly.
It wouldbe better to copy paste them line-by-line and google each command to understand what it does.

## Getting Started

### Installation

Simply clone this repository with git.

### Usage

All scripts are meant to be run from the PowerShell terminal.

You must launch powershell as Administrator and run this command first:

    Set-ExecutionPolicy Bypass -Scope Process -Force

### Commands

`.\clean.ps1` - Remove various files to reduce disk usage, similar to CCleaner.

`.\repartition.\ps1` - Shrink the Windows partition and use the remaining space for new Linux partition(s).

`.\install-vm.ps1` - Install Linux on the new partition(s) and add to boot menu.

`.\unclean.ps1` - Add important files remvoed by `clean.ps1`, such as swap and hibernation files.

