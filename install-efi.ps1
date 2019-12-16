# Automated install of an ISO file

Write-host "Started."

$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$root_dir="${letter}:"
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$iso = "${tunic_dir}\linux.iso"

#TODO: replace mkdir with better ps command
mkdir "$tunic_dir" -force

$partc = get-partition -driveletter C 
if( (get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR' ) {
    Write-host "Converting from MBR to GPT..."
    mbr2gpt /validate /allowfullos
    mbr2gpt /convert /allowfullos
}

if ( -not (Test-Path "$iso") ) {
    # Test location.  TODO: remove.
    $ciso = 'X:\Downloads\linuxmint-19.2-cinnamon-64bit.iso'
    if ( Test-Path "$ciso" ) {
        Write-host "Copying ISO..."
        copy "$ciso" "$iso"
    } else {
        Write-host "Downloading ISO... (this takes a long time)"
        try {
            (New-Object System.Net.WebClient).DownloadFile($iso_url, "$iso")
            #TODO: verify integrity
        } catch {
            Remove-Item "$iso"
            Throw "Download failed"
        }
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
    # Grub
    mkdir "${efi}\boot\grub" -force
    #TODO: shimx64.efi (shim*.deb file).
    copy "${usb}\boot\grub\x86_64-efi" "${efi}\boot\grub\." -recurse
    copy "${usb}\EFI\BOOT\grubx64.efi" "${efi}\boot\grub\."
    copy "files\grub.cfg" "${efi}\boot\grub\."
    # Preseed
    copy "files\preseed.cfg" "${tunic_dir}\."
    # iso
    #TODO: remove if iso loopback works
    Write-host "Copying ISO..."
    copy "${usb}\*" "${root_dir}\." -recurse

    dismount-diskimage -imagepath "$iso"
}

$osloader = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
bcdedit /set         "$osloader" device "partition=$efi"
if ( Test-Path "$efi\boot\grub\shimx86.efi" ) {
    bcdedit /set         "$osloader" path \boot\grub\shimx64.efi
} else {
    bcdedit /set         "$osloader" path \boot\grub\grubx64.efi
}
bcdedit /set         "$osloader" description "Linux ISO"
bcdedit /deletevalue "$osloader" locale
bcdedit /deletevalue "$osloader" inherit
bcdedit /deletevalue "$osloader" default
bcdedit /deletevalue "$osloader" resumeobject
bcdedit /deletevalue "$osloader" displayorder
bcdedit /deletevalue "$osloader" toolsdisplayorder
bcdedit /deletevalue "$osloader" timeout
bcdedit /set '{fwbootmgr}' displayorder "$osloader" /addfirst

mountvol $efi /d

Write-host "ISO Install complete.  Time to reboot."

shutdown /r /t 1

