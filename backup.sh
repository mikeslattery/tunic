#!/bin/sh

# Backup boot partition before installing grub

xz -z9 /dev/sda1 > /mnt/c/linux/part1.xz

mkdir /mnt/part1
mount /dev/sda1 /mnt/part1
zip -r /mnt/c/linux/part1.zip /mnt/part1

#TODO:
# get proper path to part1, C:
# MBR (or equiv) backup
