# Reseach and References

## References

### Backup and Recovery

* https://www.howtogeek.com/167984/how-to-create-and-restore-system-image-backups-on-windows-8.1/
* https://en.wikipedia.org/wiki/Comparison_of_disk_cloning_software
* http://odin-win.sourceforge.net/
* http://www.invoke-ir.com/2015/06/ontheforensictrail-part3.html
* https://devblogs.microsoft.com/scripting/use-powershell-to-interact-with-the-windows-api-part-1/
* https://code.msdn.microsoft.com/windowsapps/CCS-LABS-C-Low-Level-Disk-91676ca9
* https://tuxboot.org/

### Cleanup

* https://social.technet.microsoft.com/Forums/en-US/d053e005-c5fd-45bd-9bab-0379f31dba7a/how-to-set-the-no-paging-file-option-within-a-powershell-script?forum=ITCG
* https://stackoverflow.com/questions/37813441/powershell-script-to-set-the-size-of-pagefile-sys
* https://gallery.technet.microsoft.com/scriptcenter/Script-to-delete-System-4960775a
* https://superuser.com/a/1347749
* https://www.tenforums.com/tutorials/4189-turn-off-fast-startup-windows-10-a.html
* https://windowsreport.com/delete-system-error-memory-dump-files-in-windows/
* https://stackoverflow.com/questions/6035112/disable-application-crash-dumps-on-windows-7

### Install Linux

* https://phoenixnap.dl.sourceforge.net/project/osboxes/v/vb/31-Lx-M-t/19.2/Cinnamon/19-2C-64bit.7z
* https://www.groovypost.com/howto/dual-boot-windows-10-linux/
* https://www.dell.com/support/article/us/en/04/sln151664/how-to-install-ubuntu-linux-on-your-dell-pc

### Downloads
* https://github.com/unetbootin/unetbootin/blob/master/src/unetbootin/distrolst.cpp

### ISO

* https://askubuntu.com/questions/484434/install-ubuntu-without-cd-and-usb-how
* https://blogs.gnome.org/muelli/2016/08/remastering-a-custom-ubuntu-auto-install-iso/
* https://github.com/core-process/linux-unattended-installation/

### VM

* https://www.perkin.org.uk/posts/create-virtualbox-vm-from-the-command-line.html
* https://www.oracle.com/technical-resources/articles/it-infrastructure/admin-manage-vbox-cli.html
* https://www.virtualbox.org/ticket/8760 - locking
* https://www.howtogeek.com/213145/how-to%C2%A0convert-a-physical-windows-or-linux-pc-to-a-virtual-machine/ggj
* https://app.vagrantup.com/Microsoft/boxes/EdgeOnWindows10
* https://github.com/samrocketman/vagrant-windows/blob/master/windows10/Vagrantfile
* https://www.vagrantup.com/docs/provisioning/shell.html

### Testing and Support

* https://www.microsoft.com/en-us/download/details.aspx?id=8002 - XP
* https://www.makeuseof.com/tag/download-windows-xp-for-free-and-legally-straight-from-microsoft-si/

### Boot Menu

#### Repartitioning

* http://www.smorgasbork.com/2019/04/23/fedora-windows-10-dual-boot-on-dell-inspiron/
* https://docs.microsoft.com/en-us/powershell/module/bitlocker/suspend-bitlocker?view=win10-ps

#### MBR

* https://www.linuxquestions.org/questions/linux-general-1/using-bcdedit-to-configure-a-multiboot-system-and-add-linux-4175644308/
* https://wiki.archlinux.org/index.php/Dual_boot_with_Windows/SafeBoot
* https://docs.microsoft.com/en-us/windows/deployment/mbr-to-gpt

#### EFI

* https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-and-gpt-faq
* https://wiki.archlinux.org/index.php/EFI_system_partition
* https://forums.linuxmint.com/viewtopic.php?t=300030
* https://askubuntu.com/questions/342365/what-is-the-difference-between-grubx64-and-shimx64
* https://wiki.archlinux.org/index.php/EFI_system_partition
* https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcd-system-store-settings-for-uefi
* http://www.rodsbooks.com/linux-uefi/
* https://neosmart.net/wiki/bcdedit/
* https://askubuntu.com/questions/831216/how-can-i-reinstall-grub-to-the-efi-partition
* https://www.codeproject.com/Articles/833655/Modify-Windows-BCD-using-Powershell

### Automated Install

#### Ubiquity

* https://code.launchpad.net/ubiquity
* https://wiki.ubuntu.com/UbiquityAutomation
* https://github.com/linuxmint/ubiquity/blob/master/d-i/source/preseed/debian/file-preseed.postinst
* https://github.com/linuxmint/ubiquity/blob/master/bin/ubiquity
* https://github.com/linuxmint/ubiquity/blob/master/d-i/source/preseed/preseed.sh

#### Preseeding

* https://www.leifove.com/2016/11/fully-automated-linux-mint-desktop.html
* https://help.ubuntu.com/lts/installation-guide/armhf/apbs02.html
* https://askubuntu.com/questions/1002043/how-to-an-unattended-installation-of-ubuntu-16-04-on-a-disk-with-existing-os
* https://github.com/core-process/linux-unattended-installation/tree/master/ubuntu/18.04/custom
* https://www.leifove.com/2016/11/fully-automated-linux-mint-desktop.html
* https://debian-handbook.info/browse/stable/sect.automated-installation.html
* https://www.debian.org/releases/stable/example-preseed.txt
* https://www.packer.io/guides/automatic-operating-system-installs/preseed_ubuntu.html
* https://askubuntu.com/questions/457528/how-do-i-create-an-efi-bootable-iso-of-a-customized-version-of-ubuntu
* https://askubuntu.com/questions/806820/how-do-i-create-a-completely-unattended-install-of-ubuntu-desktop-16-04-1-lts
* https://github.com/hvanderlaan/ubuntu-unattended

#### Kickstart

* https://help.ubuntu.com/community/KickstartCompatibility
* http://gyk.lt/ubuntu-16-04-desktop-unattended-installation/

#### Migration

* https://git.launchpad.net/ubiquity/tree/ubiquity/plugins/ubi-migrationassistant.py?id=251afaeba2ee760267bd0253d24ffa6b668239a2

### Post Install

These are things that can be used after the install for better integration between the partitions.

* https://www.glump.net/howto/desktop/seamless-remote-linux-desktop-in-windows
* https://www.reddit.com/r/linuxquestions/comments/e964o5/way_to_reboot_to_windows_from_within_linux/

