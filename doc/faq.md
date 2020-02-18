# FAQ

### Tunic ran and then rebooted back to Windows

Sometimes Windows updates removes Tunic's grub menu entry.
Install Windows updates, reboot, and try again.

### How can I remove Tunic?

If anything goes wrong during the use of Tunic, you can fully uninstall it
with the following commands in a PowerShell window as an Administrator.

To remove the boot menu and the downloaded files:

```
bcdedit /delete $(cat C:\ProgramData\tunic\bcd.id)
rm C:\ProgramData\tunic -recurse -force
rm ~/Downloads/*.iso
```

To remove grub files.
Don't run this after you have successfully installed Linux or it won't boot.

```
mountvol S: /s
rm S:\boot -recurse -force
mountvol S: /d
```
If you had attempted dual boot, you may want to expand your C:
partition back to full size with this tool:
```
diskmgmt.msc
```

### I get the Tunic boot menu but nothing works.

You many want to uninstall tunic and try again.
Use the "Microsoft Windows" menu item to boot into Windows
and follow the "How can I remove Tunic?" instructions in this FAQ.

If you can't boot into Windows, you'll have to go into your BIOS and
[change the boot order](https://www.lifewire.com/change-the-boot-order-in-bios-2624528).

### When I download tunic.exe it disappears

Some malware falsely treats Tunic as malware.
Tunic replaces your bootloader which can look suspicious.

See how to whitelist Tunic at:
[Windows Defender](https://www.addictivetips.com/windows-tips/whitelist-apps-in-the-smartscreen-on-windows-10/).

For more information see [security](security.md).

### How can I contact the author of Tunic?

* [Enter an issue](https://github.com/mikeslattery/tunic/issues/new) in Github
* Chat directly [on reddit](https://www.reddit.com/u/funbike).

