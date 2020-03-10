# Tunic Linux Installer for Windows
# Copyright (c) Michael Slattery under GPLv3 with NO warranty.
# For more info see  https://www.gnu.org/licenses/gpl-3.0.html#section15

#    'Elementary OS - 5.1' = '';
#    'Zorin OS - 15.1' = '';
#    'Debian - 10/buster' = '';
#    'Debian - Testing' = '';
#    'AntiX - 19.1' = '';
#    'KDE Neon'


```
```
### tunic.ps1
- test full install
* windows 7
 - disable updates
* Windows 7 / Python
 - new branch
 - python3, gtk, 32 bit, no choco
 - hello world - show hi/hello.txt
 - deploy with subdirs to windows 7 32 bit
 - arch: unit tests, MVP, mock OS
 - classes: powershell, wmi, exec
 - versions
   - defer to ubiquity, [x] disclaimer, static cfg
   - download iso, progress page
   - checks
   - locale/dynamic preseed
   - distro picker
   - user
   - install type, disk sizing
* Downloads
 - If pwsh<3, install .NET 4.5.  Check for and download
     https://docs.microsoft.com/en-us/powershell/scripting/wmf/setup/install-configure?view=powershell-7
     `Start-Process -FilePath D:\path\to\dotnetfx45_full_x86_x64.exe -ArgumentList "/q /norestart" -Wait -Verb RunAs`
     `echo $?`
 - If pwsh<3, install Powershell 3 for Windows 7 w/WMI, WinRM.
* Check pending updates on restart
* Require 6.1.7601 (64 bit)
* $mount test
* distros
    $vmlinux = (dir 'D:\' -file -filter '*vmlinu*' -recurse).FullName.toLower() -replace '^\w:','' -replace '\\','/'
    $initrd  = (dir 'D:\' -file -filter '*initrd*' -recurse).FullName.toLower() -replace '^\w:','' -replace '\\','/'
    
    # only work if a single hit.  otherwise use default, even if it doesn't exist
    #$global:data.iso_url = 'ubuntu-18.04.3-desktop-amd64.iso'
    #$global:data.iso_url = 'deepin-15.11-amd64.iso'
    import and modify grub  /boot/grub/grub.cfg
    prefix (usb) to all paths
        grep linux grub.cfg | sed -r 's|([ \t=])/|\1(usb)/|g; s| file=[^ ]+ | |g s|iso-scan/filename=[^ ]+||g'
    add "kernel-params" to distros.ps1 - e.g. automatic-ubiquity
    inject preseed: file=, iso-scan/filename=
    reduce timeout or add if not exists.  3s
* distro test - debug mode
  - preseed on success command that writes to a shared folder to let host know it all worked!
    - install vbox additions
    - log files
    - snapshot
    - shut down VM after startup
    - copy .iso back to host, if not exists
  - test waits for shutdown of VM and moves to next distro
    - on a very long timeout, kill it and mark as failure.
    - check that a snapshot was created
* Ubuntu 19.10 errors - can't umount /cdrom
* Download all dependencies and package, if compatible
  - grub-for-windows.zip
  - 18.04's grubx64.efi
  - PopOS's shimx64.efi
  - windowsZones.xml
  - 7z.exe (may not need it)
  - THIRDPARTYLICENSE
* List of legal Qs
  - best way to list 3rd party licenses
  - license for shimx64?
  - gpl2 usable?
* nvidia R&D
* keyboard
* full-disk: wait X min, screenshot
  - branch
  - checkout various commit-id's or stashes
* debug boolean in $data
  - branch
  - fast - skip extra packages
  - install vbox guest additions
  - install openssh-server
* How to help doc
  - relax risk
* tesserat
* MBR
* Win 7.  VM.  Test
* Win 7, EFI/MBR, 32/64 bit (hardware) testing
* reboot-continue (to delete swap)
* Advanced options
* icons: os-uninstall, Windows files, 
* 1.0
* abort.sh (also before.sh, after.sh)
* bitlocker
  - get recovery key and tell user to write it down.
  - GRUB_TERMINAL=console
  - requires secure boot.
  - https://www.ctrl.blog/entry/dual-boot-bitlocker-device.html
* uninstall - bcd import, delete part2, expand C:, delete tunic grub
* log dump
* pre-install: bit-torrent client seeding ubuntu installs
* 32 bit
* if laptop install TLP http://www.techcrafters.com/scripts/windows-system-management/determine-whether-a-machine-is-laptop-or-not.html
### Testing
### Bling
* ico
* Spash (during free space calc)
* screenshot(s)
### tech debt
* download to temp file and move
* hash password
* distros: key, sig url
* nsis - ico
* grub protection task
* test bcd restore
* grub-installer update-grub workaround in preseed.cfg
* grub move to $ESP/tunic
* after.sh
* refactor - squash + hide, cli api, globals
---
* keyboard select - https://github.com/linuxmint/ubiquity/blob/master/ubiquity/misc.py#L672
* detect pending updates.  refuse to install

Help me
* GPL headers
* shim
* screenshot


* calc avilable as partition gap + sizemin - 2.1
* required vs supported

cards: checks, input, advanced, progress

## Check
* Always show (even if briefly)
* if all succeed, go to next
* if fail, exit, re-check buttons.

## Basic questions
* C: size, free
* disk number: 1
* Shrink Windows by: 10 GB
* available space
* "Tunic will use available space."
* [Clean] button
* Username(current) + Password + Password
* Computer name
* Distro: [Linux Mint, Cinnamon, 64 bit]
* [ ] Advanced
* [ ] Agree
* Continue

# Advanced options
* ISO URL or file: https://...
* Browse Config files (dir of generated preseed.cfg, grub.cfg, ks.cfg)
* [ ] Skip shrink partition (clean, disable swap, defrag, reboot-cont)
* [ ] Skip Ubiquity UI
* [x] Reboot now 

# validation
* https://stackoverflow.com/questions/4645126/looking-for-regex-code-for-hostname-machine-name-validation
* https://stackoverflow.com/questions/1221985/how-to-validate-a-user-name-with-regex
* everything is non null
* shrink <=  available
* either: shrink size or unused space is > ubuntu requirement + iso + new-efi
* accept = checked

## Basic questions - progress

* PSJob in background
* Abort button
* if, MBR unhide Continue button
* Converting to EFI n/a (don't auto-reboot if this is done)
* Remove swap
* Defragmenting     Done
* Add swap
* Partitioning      In Progress
* Downloading       To do
* enable Continue

# preseed values
(Get-WinSystemLocale).name -eq 'en-US'
(Get-WinSystemLocale).textInfo.culturename -eq 'en'
(Get-Culture).TwoLetterISOLanguageName -eq 'en'
(Get-Culture).Name -eq 'en-US'
(New-Object System.Globalization.RegionInfo (Get-Culture).Name).TwoLetterISORegionName -eq 'US'


# loop
$form = None
while($true) {
    if(! $form ) $form.close()
    source view.ps1
    $form.show()
}

https://imgur.com/a/4xC0xsa
    <# Failed testing, usu. because of paths.
    @{
        name='Pop!_OS - 19.10';
        url='https://pop-iso.sfo2.cdn.digitaloceanspaces.com/19.10/amd64/intel/11/pop-os_19.10_amd64_intel_11.iso';
    }
    @{
        name='Pop!_OS - 18.04/LTS';
        url='https://pop-iso.sfo2.cdn.digitaloceanspaces.com/18.04/amd64/intel/58/pop-os_18.04_amd64_intel_58.iso';
    },
    @{
        name='Deepin 15.11';
        url='https://osdn.net/projects/deepin/storage/15.11/deepin-15.11-amd64.iso';
    }
    #>

insmod ntfs
insmod part_gpt

# get iso_path, real_iso_path and preseed_path
source /boot/grub/grub.var.cfg
source /boot/grub/grub.params.cfg

set iso_path="$real_iso_path automatic-ubiquity"

# Load distro's cfg with iso root
```
set efi="$root"
search --set=ntfs --file "$real_iso_path"
loopback loop ($ntfs)"$real_iso_path"
set root=(loop)
source /boot/grub/grub.cfg
set root="$efi"

set timeout=3

#TODO: win menu goes there
linux   /casper/vmlinuz  file=/cdrom/preseed/linuxmint.seed boot=casper iso-scan/filename=${iso_path} quiet splash --
initrd  /casper/initrd.lz

linux (loop)/casper/vmlinuz file=/isodevice${tunic_dir}/preseed.cfg automatic-ubiquity boot=casper iso-scan/filename=${iso_path} toram noprompt --
initrd (loop)/casper/initrd.lz
-----
pip install pyinstaller
pip install pywin32 wmi
pip install wmi

--- windows7
sed -rn '/^\s*+#/d; /\{/d; s/remove-item//i; s/new-object//i; s/start-process//i; s/write-host//i; s/out-null//i; s/[gs]et-content//i; s/test-path//i; s/where-object//i; s/^.*\b(\w+-\w+).*$/\1/p' tunic.ps1 | tr '[A-Z]' '[a-z]' | grep -Ev 'as-is|import-module|new-itemproperty|pop-os|re-part|set-loca|windirstat|xfce|7-zip|desktop-amd|remove-item|restart-computer|re-enabl' | sort | uniq -c | sort
```
r!xsel -o

/disable-windowserrorreporting
/enable-windowserrorreporting
enable-computerrestore
disable-computerrestore

get-culture
/get-timezone

/complete-bitstransfer
/resume-bitstransfer
/start-bitstransfer

add-type

/get-bitlockervolume

/confirm-securebootuefi
/optimize-volume
/get-partitionsupportedsize
/resize-partition
/get-volume
/get-disk
/dismount-diskimage
/get-partition

