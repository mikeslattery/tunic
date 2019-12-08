Write-host "Started."

$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$iso = "${tunic_dir}\linux.iso"

#TODO: replace mkdir with better ps command
mkdir "$tunic_dir" -force

if ( -not (Test-Path "$iso") ) {
    # Test location.  TODO: remove.
    $ciso = 'X:\Downloads\linuxmint-19.2-cinnamon-64bit.iso'
    if ( Test-Path "$ciso" ) {
        Write-host "Copying ISO..."
        copy "$ciso" "$iso"
    } else {
        Write-host "Downloading ISO... (this takes a long time)"
        (New-Object System.Net.WebClient).DownloadFile($iso_url, "$iso")
    }
}

Write-host "Installing Grub..."

# TODO: allocate drive letter.  try..finally
#$efi = (ls function:[d-z]: -n | ?{ !(test-path $_) } | random)
$efi = "S:"
if ( -not (Test-Path "$efi") ) {
    mountvol $efi /s
}

if ( -not (Test-Path "$efi\boot\grub") ) {
    $usb = "$(( mount-diskimage -imagepath "$iso" | get-volume ).driveletter):"
    mkdir "${efi}\boot\grub" -force
    copy "${usb}\boot\grub\x86_64-efi" "${efi}\boot\grub\." -recurse
    copy "${usb}\EFI\BOOT\grubx64.efi" "$efi\boot\grub\."
    copy "files\grub.cfg" "$efi\boot\grub\."
    copy "files\preceed.cfg" "$tunic_dir"
    copy "files\ks.cfg" "$tunic_dir"
    dismount-diskimage -imagepath "$iso"
}

$ubuntu = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
bcdedit /set         "$ubuntu" device "partition=$efi"
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

mountvol $efi /d

Write-host "ISO Install complete.  Time to reboot."

#TODO: uncomment
# shutdown /r /t 1
# exit

