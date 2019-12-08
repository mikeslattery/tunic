Write-host "Started."

# TODO: Must be on C: and be full path
$iso = "${env:HOME}\Downloads\linuxmint-19.2-cinnamon-64bit.iso"

if ( -not (Test-Path "$iso") ) {
    # TODO: Download iso from website
    $ciso = 'X:\Downloads\linuxmint-19.2-cinnamon-64bit.iso'
    copy "$ciso" "$iso"
}


# TODO: allocate drive letter
$efi = "S:"
if ( -not (Test-Path "$efi") ) {
    mountvol $efi /s
}

$usb = "$(( mount-diskimage -imagepath "$iso" | get-volume ).driveletter):"
# /boot/grub/x86-64-efi/ntfs.mod
# /boot/grub/x86-64-efi/part_gpt.mod

if ( -not (Test-Path "$efi\boot\grub") ) {
    mkdir -force "${efi}\boot\grub"
    copy "${usb}\boot\grub\x86_64-efi" "${efi}\boot\grub\." -recurse
    copy "${usb}\EFI\BOOT\grubx64.efi" "$efi\boot\grub\."
    copy "files\grub.cfg" "$efi\boot\grub\."
}

dismount-diskimage -imagepath "$iso"

#TODO: may have to copy or use WMI to create exact entry
#https://www.codeproject.com/Articles/833655/Modify-Windows-BCD-using-Powershell
$ubuntu = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
bcdedit /set         "$ubuntu" device "partition=$efi"
#bcdedit /set         "$ubuntu" path \EFI\ubuntu\grubx64.efi
bcdedit /set         "$ubuntu" path \boot\grub\grubx64.efi
bcdedit /set         "$ubuntu" description "Linux ISO"
bcdedit /deletevalue "$ubuntu" locale
bcdedit /deletevalue "$ubuntu" inherit
bcdedit /deletevalue "$ubuntu" default
bcdedit /deletevalue "$ubuntu" resumeobject
bcdedit /deletevalue "$ubuntu" displayorder
bcdedit /deletevalue "$ubuntu" toolsdisplayorder
bcdedit /deletevalue "$ubuntu" timeout
bcdedit /set '{fwbootmgr}' displayorder "$ubuntu" /addfirst

#mountvol $efi /d

# shutdown /r /t 0
# exit

#TODO: remove
write-host "efi=$efi iso=$iso ubuntu=$ubuntu"
