# Automated install of an ISO file

if( $args[0] -eq 'noop') { exit } # Syntax check

$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$root_dir="${letter}:"
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$tunic_data="${tunic_dir}"
$iso = "${tunic_data}\linux.iso"

# Do very basic initialization
function init() {
    mkdir "$tunic_dir" -force | out-null
}

# Disable swap, hibernate, restore, error reports, dumps
function disableSwap() {
    Write-Host "Disabling swap..."
    # Turn off hibernation and fast start
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
    powercfg.exe /h off
    # Disable swap
    $computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
    $computersys.AutomaticManagedPagefile = $False
    $computersys.Put()
    #TODO: failed: wmic pagefile delete

    $pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'"
    $pagefile.InitialSize = 0
    $pagefile.MaximumSize = 0
    $pagefile.Put()
    #ALT: delete or move pagefile.sys
    #ALT: wmic computersystem set AutomaticManagedPagefile=False
    #ALT: wmic pagefileset where name="C:\\pagefile.sys" delete

    #TODO: REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl" /V CrashDumpEnabled /T REG_DWORD /D 0 /F
    #TODO: REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting" /v Disabled /T REG_DWORD /D 1 /F
    Disable-WindowsErrorReporting
    Disable-ComputerRestore -Drive "C:\"

    Write-Host "Swap disabled."
}

function enableSwap() {
    Write-Host "Re-enabling Swap"

    Enable-ComputerRestore -Drive C:
    Enable-WindowsErrorReporting

    # Enable Swap
    wmic pagefileset create name="C:\\pagefile.sys"
    wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=2048,MaximumSize=2048
    wmic computersystem set AutomaticManagedPagefile=True

    # Enable Hibernate
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 1 /F
    powercfg.exe /h on
}

function clean() {
    # Turn off swap
    Write-Host "Cleaning file system..."

    $letter = $env:HOMEDRIVE[0]

    # Cleanup
    Cleanmgr /sagerun:16
    Get-ComputerRestorePoint | Delete-ComputerRestorePoint -WhatIf 
    fsutil usn deletejournal /d /n "${letter}:"
    vssadmin delete shadows /all /quiet
    Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    Clear-WindowsDiagnosticData -Force

    #TODO: chkdsk "${letter}:"

    Write-Host "Clean done."
}

function defrag() {
    Write-Host "Defragmenting disk..."
    Optimize-Volume -DriveLetter $letter -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority
}

function backupEfi() {
   param([string]$file)
    # TODO: from repartition.ps1
}

function checks() {
    # efi
    # enough space for windows.  for linux.
    # fast boot off
}

function repartition() {
    param([int]$disknum, [int]$partnum)
}


function toEfi() {
    $partc = get-partition -driveletter C 
    if( (get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR' ) {
        Write-host "Converting from MBR to GPT..."
        #backupMbr
        mbr2gpt /validate /allowfullos
        mbr2gpt /convert /allowfullos
    }
}

function downloadIso() {
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
}

function installGrub() {
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
        mkdir "${efi}\boot\grub" -force | out-null
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

        dismount-diskimage -imagepath "$iso" | out-null
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
}

Write-host "Started."
 
$op = $args[0]

init
switch($op) {
    {$_ -eq "install-prep" } {
        # The user is watching, so let's get slow stuff out of the way first.
        clean
        disableSwap
        defrag
        downloadIso
        toEfi   # Warn user to change fw.  boot to fwsetup
        #rebootAndContinue "install"
    }
    {$_ -eq "get-info" } {
        #outputs json for use in NSIS
        #out: letter, disk-type, parts(offset, current, free, available)
    }
    {$_ -eq "download-iso" } {
        # Separated for testing purposes
        downloadIso
    }
    {$_ -eq "install" } {
        checks
        #enableSwap
        downloadIso  # in case install-prep wasn't run
        #backupEfi "..."
        installGrub
        #backupEfi "..."
        #setSizes -windows 30GB -system 20GB -user 90GB -iso 2GB
        #installIsoVolume -delete-file
        Restart-Computer # boot into linux
    }
    {$_ -eq "restore-efi" } {
        #restoreEfi $args[1]
    }
    {$_ -eq "uninstall" } {
        # remove linux, remove grub, remove iso vol
        #Restart-Computer
    }
    default {
        throw "Unknown command"
    }
}

