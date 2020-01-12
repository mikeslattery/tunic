# Automated install of an ISO file

if( $args[0] -eq 'noop') { exit } # for syntax checking

$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$root_dir="${letter}:"
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$tunic_data="${tunic_dir}"
$iso = "${tunic_data}\linux.iso"

$MIN_DISK_FB = 15

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

#TODO: custom size
    $pagefile = gwmi win32_pagefilesetting
    $pagefile.delete()

    #$pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'"
    #$pagefile.InitialSize = 0
    #$pagefile.MaximumSize = 0
    #$pagefile.Put()
    #ALT: delete or move pagefile.sys
    #wmic computersystem set AutomaticManagedPagefile=False
    #wmic pagefileset where name="C:\pagefile.sys" delete

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
    # TODO: see if hibernate is support and/or if it was on before.
    powercfg.exe /h on
}

function clean() {
    # Turn off swap
    Write-Host "Cleaning file system..."

    $letter = $env:HOMEDRIVE[0]

    # Cleanup
    Cleanmgr /sagerun:16
    Get-ComputerRestorePoint | Delete-ComputerRestorePoint
    fsutil usn deletejournal /d /n "${letter}:"
    vssadmin delete shadows /all /quiet
    Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    Clear-WindowsDiagnosticData -Force

    #TODO: chkdsk "${letter}:"

    Write-Host "Clean done."
}

function defrag() {
    Write-Host "Defragmenting disk..."
    powercfg.exe /h off
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
    Optimize-Volume -DriveLetter $letter -Defrag
    powercfg.exe /h on
}

function backupEfi() {
     param([string]$file)
     #TODO: from repartition.ps1
}

# Returns true if Linux can be installed.
function checks() {
    #[System.Environment]::Is64BitOperatingSystem -and `
    #[System.Environment]::OSVersion.version.major >= 10 -and `
    #[System.Environment]::Version.major >= 3 -and `
    #([Security.Principal.WindowsPrincipal] `
    #  [Security.Principal.WindowsIdentity]::GetCurrent() `
    #).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and `
    #(get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR')
    #TODO: doesn't work in VM: Confirm-SecureBootUEFI
    # existence of all pwsh lib functions
    # Bitlocker:
    #$BLinfo = Get-Bitlockervolume
    #if($blinfo.ProtectionStatus -eq 'On' -and $blinfo.EncryptionPercentage -eq '100'){
    #    write-output "'$env:computername - '$($blinfo.MountPoint)' is encrypted"
    #}
}

function checkSpace() {
    # enough space for windows.  for linux.
    # plus iso x2
}

function toEfi() {
    $partc = get-partition -driveletter C 
    if( (get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR' ) {
        Write-host "Converting from MBR to GPT..."
        #backupMbr
        mbr2gpt /validate /allowfullos
        mbr2gpt /convert  /allowfullos
    }
}

function downloadIso() {
    if ( -not (Test-Path "$iso") ) {
        $ciso = 'Z:\Downloads\linuxmint-19.2-cinnamon-64bit.iso'
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

# Returns the Linux timezone converted from Windows.
function getLinuxTimeZone() {

    # Download and load list of timezones

    $url = 'https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml'
    $file = "$env:TEMP\windowsZones.xml"
    if( ! (Test-Path $file -ErrorAction SilentlyContinue) ) {
        $web = (New-Object System.Net.WebClient)
        $web.DownloadFile($url, $file)
    }
    [xml]$xml = Get-Content $file
    $nodes = $xml.supplementalData.windowsZones.mapTimezones.childNodes

    # Get Windows timezone and country code.

    $wtz = (get-timezone).id
    $territory = (New-Object System.Globalization.RegionInfo (Get-Culture).Name).TwoLetterISORegionName

    # Scan for Linux equivalent

    $ltz =     ($nodes | where-object { $_.other -eq $wtz -and $_.territory -eq $territory } ).type
    if( ! $ltz ) {
        # Direct hit failed.  Use the generic territory, 001.  This is most common case.
        $ltz = ($nodes | where-object { $_.other -eq $wtz -and $_.territory -eq '001' } ).type
    }
    if( ! $ltz ) {
        # Any match by name.
        $ltz = ($nodes | where-object { $_.other -eq $wtz } | select -first 1 ).type
    }
    if( ! $ltz ) {
        $ltz = 'UTC'
    }

    return $ltz
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
        #Write-host "Copying ISO..."
        copy "${usb}\*" "${root_dir}\." -recurse

        dismount-diskimage -imagepath "$iso" | out-null
    }

    $osloader = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
    bcdedit /set         "$osloader" device "partition=$efi"
    if ( Test-Path "$efi\boot\grub\shimx64.efi" ) {
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

function getInfo() {
    $c_part = (get-partition -driveletter $letter)[0]
    $c_minsize = (get-partitionsupportedsize -driveletter $letter).sizeMin
    @{
        disk = $c_part.diskNumber;
        letter = $letter;
        number = $c_part.partitionNumber;
        size = $c_part.size;
        free = (get-volume -driveletter $letter).sizeRemaining;
        available = ($c_part.size - $c_minsize);
        offset = $c_part.offset
    }
}

function createIsoPartition() {
    param([int] $space)

    Write-Host 'Mounting ISO...'

    # Gather stats
    $info = getInfo
    $iso_size = ( get-childitem -path "$iso" ).length
    $iso_offset = $info.offset + $info.size - $iso_size

    if( $info.available -lt $iso_size ) {
        throw "Not enough space to create ISO partition"
    }

    # Partitioning
    $c_size = ( $info.size - $iso_size - $space )
    resize-partition `
        -diskNumber $info.disk `
        -partitionNumber $info.number `
        -size $c_size

    $iso_part = new-partition `
        -disknumber $info.disk `
        -assignDriveLetter `
        -offset $iso_offset -size $iso_size

    # Copy ISO
    $iso_part | format-volume -fileSystem FAT32

    #TODO: mount iso
    $usb = "${iso_part.driveLetter}:"

    copy "$iso" "$usb" -recurse

    #TODO: umount

    $iso_part.partitionNumber 
}

# Because PS sucks, we need to make these global.

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$main = New-Object system.Windows.Forms.TableLayoutPanel
$sizeLabel = New-Object system.Windows.Forms.Label
$TotalValue = New-Object system.Windows.Forms.Label
$usedValue = New-Object system.Windows.Forms.Label
$freeValue = New-Object system.Windows.Forms.Label
$availValue = New-Object system.Windows.Forms.Label
$LinuxSize = New-Object system.Windows.Forms.TextBox
$username = New-Object system.Windows.Forms.TextBox
$password = New-Object system.Windows.Forms.TextBox
$password2 = New-Object system.Windows.Forms.TextBox
$hostname = New-Object system.Windows.Forms.TextBox
$agreeBox = New-Object system.Windows.Forms.CheckBox
$installbutton = New-Object system.Windows.Forms.Button

$progress = New-Object system.Windows.Forms.TableLayoutPanel
$defragStatus = New-Object system.Windows.Forms.Label
$partStatus = New-Object system.Windows.Forms.Label
$dlStatus = New-Object system.Windows.Forms.Label
$grubStatus = New-Object system.Windows.Forms.Label
$rebootStatus = New-Object system.Windows.Forms.Label

function calcGui() {
    $letter = $env:HOMEDRIVE[0]
    $volume = (Get-Volume -driveletter $letter)
    $partc = (get-partition -driveletter $letter)
    $partnext = (get-partition -disknumber $partc.disknumber | where-object { $_.partitionNumber -eq ($partc.partition + 1)})
    if( !! $partnext ) {
        $gap = 0
    } else {
        $gap = $partnext.offset - ( $partc.offset + $partc.size )
    }
    $total = [math]::round( $volume.size / 1GB )
    $free  = [math]::round( ($volume.sizeremaining + $gap) / 1GB )
    $avail = [math]::floor( ( (get-partitionsupportedsize -driveletter "$letter").sizeMin + $gap ) / 1GB)
    # Used by windows.  (gap is not part of calculation)
    $used  = [math]::round( ( $volume.size - $volume.sizeRemaining ) / 1GB )

    $sizeLabel.text  = "${letter}: Drive"

    $totalValue.text = "$total GB"
    $freeValue.text  = "$free GB"
    $usedValue.text  = "$used GB"
    $availValue.text = "$avail GB"

    if( ! $linuxSize.text ) {
        $linuxSize.text = "$(( [math]::max( $MIN_DISK_GB, [math]::min( [math]::floor($total / 2) , $avail ) ) ))"
    }
}

# Returns desired size of windows partition
function getPreferredSize() {
    $partc = (get-partition -driveletter $letter)
    $partnext = (get-partition -disknumber $partc.disknumber | where-object { $_.partitionNumber -eq ($partc.partitionNumber + 1)})
    if( !! $partnext ) {
        $gap = 0
    } else {
        $gap = $partnext.offset - ( $partc.offset + $partc.size )
    }

    # size entered in GUI
    $linuxSizeNum = [double]::parse( $linuxSize.text ) * 1GB
    # partition gap is already available
    $winShrink = [math]::max([double]0, $linuxSizeNum - $gap )

    return $partc.size - $winShrink
}

# Create the partition gap
function createLinuxSpace() {
    $letter = $env:HOMEDRIVE[0]
    $newPartSize = (getPreferredSize)

    resize-partition -driveletter $letter -size $newPartSize

    #$partc = (get-partition -driveletter $letter)
    #new-partition -disknumber $partc.diskNumber -offset ( $partc.offset + $partc.size ) -usemaximumsize
}

function checkFields() {
    $main.enabled = $false

    if( $password.text.length -eq 0 ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Password required.")
        $main.enabled = $true
        [Void]$password.focus()
        return $false
    }

    if( $password.text -ne $password2.text ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Passwords don't match")
        $main.enabled = $true
        [Void]$password.focus()
        return $false
    }

    if( ! $agreeBox.checked ) {
        [Void][System.Windows.Forms.Messagebox]::Show("You must agree to terms to continue.")
        $main.enabled = $true
        [Void]$agreeBox.focus()
        return $false
    }

    $linuxSizeNum = [double]::parse( $linuxSize.text ) * 1GB
    if( $linuxSizeNum -lt $MIN_DISK_GB * 1GB ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Linux requires at least ${MIN_DISK_GB}GB")
        $main.enabled = $true
        [Void]$linuxSize.focus()
        return $false
    }

    $letter = $env:HOMEDRIVE[0]
    $avail = (get-partitionsupportedsize -driveletter "$letter").sizeMin
    if( $linuxSizeNum -gt $avail ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Not enough available space.")
        $main.enabled = $true
        [Void]$linuxSize.focus()
        return $false
    }

    $main.enabled = $true
    return $true
}

function gui() {

    $Form                   = New-Object system.Windows.Forms.Form
    $Form.text              = "Tunic Linux Mint Installer"
    $Form.autosize          = $true

    # Progress Panel

    $progress.autosize          = $true
    $progress.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $progress.padding           = 10
    $progress.columnCount       = 1
    $progress.visible       = $false
    #TODO: progress fields
    #TODO: use job to run in background.
    #TODO: Stop button

    # Requirement Status Panel

    $StatusPanel              = New-Object system.Windows.Forms.TableLayoutPanel
    $StatusPanel.BackColor    = "#e3d7ed"
    $StatusPanel.autosize     = $true
    $StatusPanel.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $StatusPanel.padding      = 5
    $StatusPanel.columnCount  = 2
    $row = 0

    $defragLabel             = New-Object system.Windows.Forms.Label
    $defragLabel.text        = "Defragment"
    $defragLabel.AutoSize    = $true

    $defragStatus.text        = "To Do"
    $defragStatus.AutoSize    = $true

    $statusPanel.controls.add($defragLabel, 0, $row)
    $statusPanel.controls.add($defragStatus, 1, $row)
    $row++

    $partLabel             = New-Object system.Windows.Forms.Label
    $partLabel.text        = "Re-Partition"
    $partLabel.AutoSize    = $true

    $partStatus.text        = "To Do"
    $partStatus.AutoSize    = $true

    $statusPanel.controls.add($partLabel, 0, $row)
    $statusPanel.controls.add($partStatus, 1, $row)
    $row++

    $dlLabel             = New-Object system.Windows.Forms.Label
    $dlLabel.text        = "Download"
    $dlLabel.AutoSize    = $true

    $dlStatus.text        = "To Do"
    $dlStatus.AutoSize    = $true

    $statusPanel.controls.add($dlLabel, 0, $row)
    $statusPanel.controls.add($dlStatus, 1, $row)
    $row++

    $grubLabel             = New-Object system.Windows.Forms.Label
    $grubLabel.text        = "Install Grub"
    $grubLabel.AutoSize    = $true

    $grubStatus.text        = "To Do"
    $grubStatus.AutoSize    = $true

    $statusPanel.controls.add($grubLabel, 0, $row)
    $statusPanel.controls.add($grubStatus, 1, $row)
    $row++

    $rebootLabel             = New-Object system.Windows.Forms.Label
    $rebootLabel.text        = "Reboot"
    $rebootLabel.AutoSize    = $true

    $rebootStatus.text        = "To Do"
    $rebootStatus.AutoSize    = $true

    $statusPanel.controls.add($rebootLabel, 0, $row)
    $statusPanel.controls.add($rebootStatus, 1, $row)
    $row++

    $progress.controls.add($statusPanel)

    #TODO: button panel - Abort
    $progress.controls.add( (New-Object system.Windows.Forms.Label) )

    $form.controls.add($progress)

    # Main Input Panel

    $main.autosize          = $true
    $main.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $main.padding           = 10
    $main.columnCount       = 1

    $sizeLabel.text         = "C: Drive"
    $sizeLabel.AutoSize     = $true

    $main.controls.add($sizeLabel)

    $SizePanel              = New-Object system.Windows.Forms.TableLayoutPanel
    $SizePanel.BackColor    = "#e3d7ed"
    $sizePanel.autosize     = $true
    $sizePanel.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $sizePanel.padding      = 5
    $sizePanel.columnCount  = 2
    $row = 0

    $totalLabel             = New-Object system.Windows.Forms.Label
    $totalLabel.text        = "Total Size"
    $totalLabel.AutoSize    = $true

    $TotalValue.text        = "0 GB"
    $TotalValue.AutoSize    = $true

    $sizePanel.controls.add($totalLabel, 0, $row)
    $sizePanel.controls.add($totalValue, 1, $row)
    $row++

    $UsedLabel                       = New-Object system.Windows.Forms.Label
    $UsedLabel.text                  = "Used by Windows"
    $UsedLabel.AutoSize              = $true

    $usedValue.text                  = "0 GB"
    $usedValue.AutoSize              = $true

    $sizePanel.controls.add($UsedLabel, 0, $row)
    $sizePanel.controls.add($UsedValue, 1, $row)
    $row++

    $FreeLabel                       = New-Object system.Windows.Forms.Label
    $FreeLabel.text                  = "Free"
    $FreeLabel.AutoSize              = $true

    $freeValue.text                   = "0 GB"
    $freeValue.AutoSize               = $true

    $sizePanel.controls.add($freeLabel, 0, $row)
    $sizePanel.controls.add($freeValue, 1, $row)
    $row++

    $availLabel                       = New-Object system.Windows.Forms.Label
    $availLabel.text                  = "Available"
    $availLabel.AutoSize              = $true

    $availValue.text                   = "0 GB"
    $availValue.AutoSize               = $true

    $sizePanel.controls.add($availLabel, 0, $row)
    $sizePanel.controls.add($availValue, 1, $row)
    $row++

    $LinuxLabel             = New-Object system.Windows.Forms.Label
    $LinuxLabel.text        = "Linux Size"
    $LinuxLabel.AutoSize    = $true

    $LinuxSize.multiline    = $false
    $LinuxSize.AutoSize     = $true
    $LinuxSize.width        = 30

    $sizePanel.controls.add($linuxLabel, 0, $row)
    $sizePanel.controls.add($linuxSize, 1, $row)
    $row++

    $main.controls.add($sizePanel)

    $cleanPanel                     = New-Object system.Windows.Forms.FlowLayoutPanel
    $cleanPanel.padding      = 5
    $cleanPanel.AutoSize     = $true

    $cleanButton                     = New-Object system.Windows.Forms.Button
    $cleanButton.text                = "Clean"
    $cleanButton.tabStop = $false
    $cleanPanel.controls.add($cleanButton)

    $defragButton                   = New-Object system.Windows.Forms.Button
    $defragButton.text              = "Defrag"
    $defragButton.tabStop           = $false
    $cleanPanel.controls.add($defragButton)

    $parterButton                   = New-Object system.Windows.Forms.Button
    $parterButton.text              = "Partitions"
    $parterButton.tabStop           = $false
    $cleanPanel.controls.add($parterButton)

    $main.controls.add($cleanPanel)

    $idGroupLabel                    = New-Object system.Windows.Forms.Label
    $idGroupLabel.text               = "Identifcation"
    $idGroupLabel.AutoSize           = $true

    $main.controls.add($idGroupLabel)

    $idPanel                         = New-Object system.Windows.Forms.TableLayoutPanel
    $idPanel.autosize     = $true
    $idPanel.BackColor               = "#e3d7ed"
    $idPanel.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $idPanel.padding      = 5
    $idPanel.columnCount  = 2
    $row = 0

    $usernameLabel                    = New-Object system.Windows.Forms.Label
    $usernameLabel.text               = "User Name"
    $usernameLabel.AutoSize           = $true

    $username.multiline              = $false
    $username.AutoSize           = $true
    $username.tabStop           = $false

    $idPanel.controls.add($usernameLabel, 0, $row)
    $idPanel.controls.add($username, 1, $row)
    $row++

    $passwordLabel                    = New-Object system.Windows.Forms.Label
    $passwordLabel.text               = "Password"
    $passwordLabel.AutoSize           = $true

    $password.passwordChar           = '*'
    $password.multiline              = $false
    $password.AutoSize           = $true

    $idPanel.controls.add($passwordLabel, 0, $row)
    $idPanel.controls.add($password, 1, $row)
    $row++

    $password2Label                    = New-Object system.Windows.Forms.Label
    $password2Label.text               = "Password, again"
    $password2Label.AutoSize           = $true

    $password2.passwordChar           = '*'
    $password2.multiline              = $false
    $password2.AutoSize           = $true

    $idPanel.controls.add($password2Label, 0, $row)
    $idPanel.controls.add($password2, 1, $row)
    $row++

    $hostnameLabel                   = New-Object system.Windows.Forms.Label
    $hostnameLabel.text              = "Computer Name"
    $hostnameLabel.AutoSize          = $true

    $hostname.multiline              = $false
    $hostname.AutoSize          = $true
    $hostname.tabStop           = $false

    $idPanel.controls.add($hostnameLabel, 0, $row)
    $idPanel.controls.add($hostname, 1, $row)
    $row++

    $main.controls.add($idPanel)

    $agreeBox.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $agreeBox.text              =
        "I understand this software could cause data loss " +
        "and is provided as-is without any warrantee.  " +
        "I shall not hold the authors liable for any damages whatsoever."
    $agreeBox.AutoSize               = $false
    $agreeBox.height = 50

    $main.controls.add($agreeBox)

    $buttonPanel                     = New-Object system.Windows.Forms.FlowLayoutPanel
    $buttonPanel.padding      = 5
    $buttonPanel.AutoSize               = $true

    $abortButton                     = New-Object system.Windows.Forms.Button
    $abortButton.text                = "Abort"
    $abortButton.tabStop           = $false
    $buttonPanel.controls.add($abortButton)

    $installbutton.text              = "Continue"
    $buttonPanel.controls.add($installButton)

    $main.controls.add($buttonPanel)

    $form.controls.add($main)

    # Default feild values
    calcGui

    $username.text = [System.Environment]::UserName
    $hostname.text = [System.Environment]::MachineName

    # Actions
    
    $cleanButton.add_click({
        $main.enabled = $false
        try {
            start-process cleanmgr -wait
            calcGui
        } finally {
            $main.enabled = $true
        }
    })

    $defragButton.add_click({
        $main.enabled = $false
        try {
            start-process dfrgui -wait
            calcGui
        } finally {
            $main.enabled = $true
        }
    })

    $parterButton.add_click({
        $main.enabled = $false
        try {
            start-process diskmgmt.msc -wait
            calcGui
        } finally {
            $main.enabled = $true
        }
    })

    $abortButton.add_click( {
        $form.close()
    })

    $installButton.add_click({
        if( (checkFields) ) {
            $main.visible = $false
            $progress.visible = $true
            #TODO: Run as PSJob, remove doevents
            [System.Windows.Forms.Application]::DoEvents() 

            init

            $defragStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            defrag
            $defragStatus.text = 'Done'

            $partStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            createLinuxSpace
            $partStatus.text = 'Done'

            $dlStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            downloadIso
            $dlStatus.text = 'Done'

            $grubStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            installGrub
            $grubStatus.text = 'Done'

            $rebootStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            Restart-Computer
        }
    })

    return $form
}


$op = $args[0]

switch($op) {
    {$_ -eq "install-prep" } {
        # The user is watching, so let's get slow stuff out of the way first.
        checks
        init
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
        getInfo | convertTo-json
    }
    {$_ -eq "download-iso" } {
        # Separated for testing purposes
        downloadIso
    }
    {$_ -eq "install" } {
        checks
        checkSpace
        init
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
    {$_ -eq "disable-swap" } {
        disableSwap
        Restart-Computer
    }
    {$_ -eq "uninstall" } {
        # remove linux, remove grub, remove iso vol
        #Restart-Computer
    }
    {$_ -eq "gui2" } {
        # TODO: remove.  for testing purposes.
        $form = (gui)
        echo '---'
        $form.show()
        sleep 6
        $form.close()
    }
    default {
        checks
        $form = (gui)
        $form.showDialog()
    }
}

