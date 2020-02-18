# Security and Malware

Tunic makes deep changes your system.  This has several security implications.

## Anti-Malware Detections

Some anit-malware products falsely detect Tunic as malware.
There can be various reasons for this, but mainly it's because of bootloader changes.
Tunic is making deep changes to your system that aren't typical of user application software
but is typical of malware.
It's not surprising that this can occur.

#### Verifying Tunic is Safe Code

Probably the best way is to audit Tunic.  The main file, tunic.ps1, is only 1200 lines as of this writing.
It wouldn't take much effort to review it completely.

To check that tunic.exe only contains files from the github project, 7zip can be used to extract the contents:

```
7z x tunic.exe
```
<!--
TODO:
secure boot
passwords/encryption: grub.cfg, firmware, /home
-->
