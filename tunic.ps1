# Automated install of an ISO file

if( $args[0] -eq 'noop') { exit } # for syntax checking

$global:iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'
$global:shim_url = 'https://github.com/pop-os/iso/blob/master/data/efi/shimx64.efi.signed?raw=true'

$global:letter = $env:HOMEDRIVE[0]
$global:root_dir="${letter}:"
$global:tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$global:tunic_data="${tunic_dir}"
$global:iso = "${tunic_data}\linux.iso"

$global:MIN_DISK_FB = 15


# Do very basic initialization
if ( -not (Test-Path "$global:tunic_dir") ) {
    mkdir "$global:tunic_dir" | out-null
}

# Disable swap, hibernate, restore, error reports, dumps
function disableSwap() {
    Write-Host "Disabling swap..."

    # Turn off hibernation and fast start
    powercfg.exe /h off
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F

    # Disable swap
    $computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
    $computersys.AutomaticManagedPagefile = $False
    $computersys.Put()

    $pagefile = Get-WmiObject win32_pagefilesetting
    $pagefile.delete()

    Disable-WindowsErrorReporting
    Disable-ComputerRestore -Drive "${global:root_dir}"

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

    # Enable Hibernate (but not fast start)
    # TODO: see if hibernate is support and/or if it was on before.
    powercfg.exe /h on
}

function defrag() {
    powercfg.exe /h off
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
    Optimize-Volume -DriveLetter $global:letter -Defrag
    #TODO: powercfg.exe /h on - if was on before
}

function die($msg) {
    write-host $msg
    [System.Windows.Forms.Messagebox]::Show($msg)
    exit 1
}

function yes($q) {
    $buttons = [System.Windows.Forms.MessageBoxButtons]::OKCancel
    return [System.Windows.Forms.MessageBox]::Show("Message Text","Title", $buttons )
}

function openUrl($url) {
    [System.Diagnostics.Process]::Start($url)
}

# Returns true if Linux can be installed.
function checks() {
    if( !([Security.Principal.WindowsPrincipal] `
          [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ) {
        die( 'Must be an Administrator to run tunic' )
    }

    if( ! [System.Environment]::Is64BitOperatingSystem ) {
        die( 'Only 64 bit systems supported' )
    }
        
    if( ! [System.Environment]::OSVersion.version.major -ge 10 ) {
        die( 'Only Windows 10 supported' )
    }

    if( [System.Environment]::Version.major -lt 3 ) {
        die( 'Powershell 3 or above required' )
    }

    $partc = ( get-partition -driveLetter $global:letter )
    if( (get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR' ) {
        if( yes('UEFI required.  Would you like to read how to convert form MBR to EFI') ) {
            openUrl('https://www.windowscentral.com/how-convert-mbr-disk-gpt-move-bios-uefi-windows-10')
        }
        exit 1
    }
        
    $blInfo = Get-Bitlockervolume
    if( $blInfo.ProtectionStatus -eq 'On' ) {
        die( 'Bitlocker encrypted drive not supported.' )
    }
}

function downloadIso() {
    if ( -not (Test-Path "$global:iso") ) {
        $ciso = 'Z:\Downloads\linuxmint-19.2-cinnamon-64bit.iso'
        if ( Test-Path "$ciso" ) {
            copy "$ciso" "$global:iso"
        } else {
            try {
                (New-Object System.Net.WebClient).DownloadFile($global:iso_url, "$global:iso")
                #TODO: save to temp and move after.
                #TODO: verify integrity
            } catch {
                Remove-Item "$global:iso"
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

    $wtz = (get-timezone)
    $tzName = $wtz.id
    $territory = (New-Object System.Globalization.RegionInfo (Get-Culture).Name).TwoLetterISORegionName

    $zones = ($nodes | where-object { $_.other -eq $tzName } )
    if( $zones.count -eq 1 ) {
        $ltz = $zones[0].type
    } elseif( $zones.count -gt 1 ) {

        # Scan for exact Linux equivalent
        $ltz = ($zones | where-object { $_.territory -eq $territory } ).type
        if( ! $ltz ) {
            # Direct hit failed.  Use the generic territory.  This is most common case.
            $ltz = ($zones | where-object { $_.territory -eq '001' } ).type
        }

        # Sloppy match
        $ltz = $zones[0].type
    }
    else {
        # Match by GMT and hour difference.
        $offset = - $wtz.baseUtcOffset.totalHours
        if( $offset -eq [math]::floor($offset) -and `
                -12 -le $offset -and $offset -le 12 -and `
                $offset -ne 0 ) {

            if( $offset -gt 0 ) {
                $ltz = "Etc/GMT-${offset}"
            } else {
                $ltz = "Etc/GMT+${offset}"
            }
        }
        else {
            # We give up.  This should never happen.
            $ltz = "UTC"
        }
    }

    return $ltz
}

function expandTemplate($filename) {
    $str = ( get-content -path "$filename" )
    $str = $str.split("`n") -join "``n"
    return $ExecutionContext.InvokeCommand.ExpandString( $str )
}

function installGrub() {
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
        copy "${usb}\boot\grub\x86_64-efi" "${efi}\boot\grub\." -recurse
        copy "${usb}\EFI\BOOT\grubx64.efi" "${efi}\boot\grub\."
        #TODO: use grubx64 if secureboot is not enabled
        (New-Object System.Net.WebClient).DownloadFile($shim_url, "${efi}\boot\grub\shimx64.efi")
        copy "files\grub.cfg" "${efi}\boot\grub\."
        # Preseed
        set-content -value (expandTemplate "files\preseed.cfg") -path "${global:tunic_dir}\preseed.cfg"

        dismount-diskimage -imagepath "$global:iso" | out-null
    }

    if ( -not (Test-Path "${global:tunic_dir}\bcd-before.bak" ) ) {
        bcdedit /export "${global:tunic_dir}\bcd-before.bak"
    }

    #TODO: idempotent
    $osloader = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
    bcdedit /set         "$osloader" device "partition=$efi"
    bcdedit /set         "$osloader" path \boot\grub\shimx64.efi
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

    bcdedit /export "${global:tunic_dir}\bcd-grub.bak"
}

# Calculates globals gap and maxAvailable
function calcPartition() {
    $letter = $global:letter
    $global:partc = (get-partition -driveletter $letter)
    $disk = (get-disk -number $global:partc.diskNumber)

    # Calculate Gap
    $partnext = (get-partition -disknumber $global:partc.disknumber | where-object { $_.partitionNumber -eq ($global:partc.partitionNumber + 1)})
    if( ! $partnext ) {
        #TODO: figure out hey -1MB needed
        $global:gap = $disk.size - ( $global:partc.offset + $global:partc.size ) - 1MB
    } else {
        $global:gap = $partnext.offset - ( $global:partc.offset + $global:partc.size )
    }

    # Calculate available
    $global:maxAvailable = $global:partc.size - (get-partitionsupportedsize -driveletter "$letter").sizeMin + $global:gap

    #TODO: remove
    write-host "$($partc.partitionNumber) partc.offset,size $($partc.offset / 1GB),$($partc.size / 1GB) next.offset $($partnext.offset / 1GB) disk.size $($disk.size / 1GB) gap $($global:gap / 1GB) avail $($global:maxAvailable / 1GB)"
    write-host "$($partc.partitionNumber) partc.offset,size $($partc.offset),$($partc.size) next.offset $($partnext.offset) disk.size $($disk.size) gap $($global:gap) avail $($global:maxAvailable)"
}

function repartition() {
    $letter = $global:letter
    $global:partc = (get-partition -driveletter $letter)

    # size entered in GUI
    $linuxSizeNum = [double]::parse( $global:linuxSize.text ) * 1GB

    $shrinkBy = $linuxSizeNum - $global:gap

    $newSize = $global:partc.size - ( $shrinkBy )

    #TODO: remove
    write-host "lsize $linuxSizeNum partc.size $( $global:partc.size ) shrinkBy $shrinkBy size $newSize"

    if( $shrinkBy -gt 0 ) {
        resize-partition -driveletter $letter -size $newSize
    }
}

function calcGui() {
    calcPartition

    $letter = $global:letter
    $volume = (Get-Volume -driveletter $letter)

    $total = [math]::round( $volume.size / 1GB )
    $free  = [math]::round( $volume.sizeremaining / 1GB )
    $used  = [math]::round( ( $volume.size - $volume.sizeRemaining ) / 1GB )
    $avail = [math]::floor( $global:maxAvailable / 1GB )

    $global:sizeLabel.text  = "${letter}: Drive"

    $global:totalValue.text = "$total GB"
    $global:freeValue.text  = "$free GB"
    $global:usedValue.text  = "$used GB"
    $global:availValue.text = "$avail GB"

    if( ! $global:linuxSize.text ) {
        $global:linuxSize.text = "$(( [math]::max( $global:MIN_DISK_GB, [math]::min( [math]::floor($total / 2) , $avail ) ) ))"
    }
}

function initFields() {
    checks
    calcGui

    $userInfo = ( Get-WMIObject Win32_UserAccount | where caption -eq (whoami) )
    $fullname.text = $userInfo.fullName
    $username.text = $userInfo.name.toLower()
    $hostname.text = $userInfo.psComputerName
}

function checkFields() {
    $global:main.enabled = $false

    if( $password.text.length -eq 0 ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Password required.")
        $global:main.enabled = $true
        [Void]$global:password.focus()
        return $false
    }

    if( $global:password.text -ne $global:password2.text ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Passwords don't match")
        $global:main.enabled = $true
        [Void]$global:password.focus()
        return $false
    }

    if( ! $global:agreeBox.checked ) {
        [Void][System.Windows.Forms.Messagebox]::Show("You must agree to terms to continue.")
        $global:main.enabled = $true
        [Void]$global:agreeBox.focus()
        return $false
    }

    $linuxSizeNum = [double]::parse( $global:linuxSize.text ) * 1GB
    if( $linuxSizeNum -lt $global:MIN_DISK_GB * 1GB ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Linux requires at least ${MIN_DISK_GB}GB")
        $global:main.enabled = $true
        [Void]$global:linuxSize.focus()
        return $false
    }

    if( $linuxSizeNum -gt $global:maxAvailable ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Not enough available space.")
        $global:main.enabled = $true
        [Void]$global:linuxSize.focus()
        return $false
    }

    $global:main.enabled = $true
    return $true
}

function gui() {

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $Form                   = New-Object system.Windows.Forms.Form
    $Form.text              = "Tunic Linux Mint Installer"
    $Form.autosize          = $true

    # Main Input Panel
    $global:main = New-Object system.Windows.Forms.TableLayoutPanel
    $main.autosize          = $true
    $main.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $main.padding           = 10
    $main.columnCount       = 1

    $global:sizeLabel = New-Object system.Windows.Forms.Label
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

    $global:TotalValue = New-Object system.Windows.Forms.Label
    $TotalValue.text        = "0 GB"
    $TotalValue.AutoSize    = $true

    $sizePanel.controls.add($totalLabel, 0, $row)
    $sizePanel.controls.add($totalValue, 1, $row)
    $row++

    $UsedLabel                       = New-Object system.Windows.Forms.Label
    $UsedLabel.text                  = "Used by Windows"
    $UsedLabel.AutoSize              = $true

    $global:usedValue = New-Object system.Windows.Forms.Label
    $usedValue.text                  = "0 GB"
    $usedValue.AutoSize              = $true

    $sizePanel.controls.add($UsedLabel, 0, $row)
    $sizePanel.controls.add($UsedValue, 1, $row)
    $row++

    $FreeLabel                       = New-Object system.Windows.Forms.Label
    $FreeLabel.text                  = "Free"
    $FreeLabel.AutoSize              = $true

    $global:freeValue = New-Object system.Windows.Forms.Label
    $freeValue.text                   = "0 GB"
    $freeValue.AutoSize               = $true

    $sizePanel.controls.add($freeLabel, 0, $row)
    $sizePanel.controls.add($freeValue, 1, $row)
    $row++

    $availLabel                       = New-Object system.Windows.Forms.Label
    $availLabel.text                  = "Available"
    $availLabel.AutoSize              = $true

    $global:availValue = New-Object system.Windows.Forms.Label
    $availValue.text                   = "0 GB"
    $availValue.AutoSize               = $true

    $sizePanel.controls.add($availLabel, 0, $row)
    $sizePanel.controls.add($availValue, 1, $row)
    $row++

    $LinuxLabel             = New-Object system.Windows.Forms.Label
    $LinuxLabel.text        = "Linux Size"
    $LinuxLabel.AutoSize    = $true

    $global:LinuxSize = New-Object system.Windows.Forms.TextBox
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

    $global:username = New-Object system.Windows.Forms.TextBox
    $username.multiline              = $false
    $username.AutoSize           = $true
    $username.tabStop           = $false

    $idPanel.controls.add($usernameLabel, 0, $row)
    $idPanel.controls.add($username, 1, $row)
    $row++

    $passwordLabel                    = New-Object system.Windows.Forms.Label
    $passwordLabel.text               = "Password"
    $passwordLabel.AutoSize           = $true

    $global:password = New-Object system.Windows.Forms.TextBox
    $password.passwordChar           = '*'
    $password.multiline              = $false
    $password.AutoSize           = $true

    $idPanel.controls.add($passwordLabel, 0, $row)
    $idPanel.controls.add($password, 1, $row)
    $row++

    $password2Label                    = New-Object system.Windows.Forms.Label
    $password2Label.text               = "Password, again"
    $password2Label.AutoSize           = $true

    $global:password2 = New-Object system.Windows.Forms.TextBox
    $password2.passwordChar           = '*'
    $password2.multiline              = $false
    $password2.AutoSize           = $true

    $idPanel.controls.add($password2Label, 0, $row)
    $idPanel.controls.add($password2, 1, $row)
    $row++

    $fullNameLabel                   = New-Object system.Windows.Forms.Label
    $fullNameLabel.text              = "Full Name"
    $fullNameLabel.AutoSize          = $true

    $global:fullName = New-Object system.Windows.Forms.TextBox
    $fullName.multiline              = $false
    $fullName.AutoSize          = $true
    $fullName.tabStop           = $false

    $idPanel.controls.add($fullNameLabel, 0, $row)
    $idPanel.controls.add($fullName, 1, $row)
    $row++

    $hostnameLabel                   = New-Object system.Windows.Forms.Label
    $hostnameLabel.text              = "Computer Name"
    $hostnameLabel.AutoSize          = $true

    $global:hostname = New-Object system.Windows.Forms.TextBox
    $hostname.multiline              = $false
    $hostname.AutoSize          = $true
    $hostname.tabStop           = $false

    $idPanel.controls.add($hostnameLabel, 0, $row)
    $idPanel.controls.add($hostname, 1, $row)
    $row++

    $main.controls.add($idPanel)

    $global:agreeBox = New-Object system.Windows.Forms.CheckBox
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

    $global:installbutton = New-Object system.Windows.Forms.Button
    $installbutton.text              = "Continue"
    $buttonPanel.controls.add($installButton)

    $main.controls.add($buttonPanel)

    $form.controls.add($main)

    # Progress Panel

    $global:progress = New-Object system.Windows.Forms.TableLayoutPanel
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

    $global:defragStatus = New-Object system.Windows.Forms.Label
    $defragStatus.text        = "To Do"
    $defragStatus.AutoSize    = $true

    $statusPanel.controls.add($defragLabel, 0, $row)
    $statusPanel.controls.add($defragStatus, 1, $row)
    $row++

    $partLabel             = New-Object system.Windows.Forms.Label
    $partLabel.text        = "Re-Partition"
    $partLabel.AutoSize    = $true

    $global:partStatus = New-Object system.Windows.Forms.Label
    $partStatus.text        = "To Do"
    $partStatus.AutoSize    = $true

    $statusPanel.controls.add($partLabel, 0, $row)
    $statusPanel.controls.add($partStatus, 1, $row)
    $row++

    $dlLabel             = New-Object system.Windows.Forms.Label
    $dlLabel.text        = "Download"
    $dlLabel.AutoSize    = $true

    $global:dlStatus = New-Object system.Windows.Forms.Label
    $dlStatus.text        = "To Do"
    $dlStatus.AutoSize    = $true

    $statusPanel.controls.add($dlLabel, 0, $row)
    $statusPanel.controls.add($dlStatus, 1, $row)
    $row++

    $grubLabel             = New-Object system.Windows.Forms.Label
    $grubLabel.text        = "Install Grub"
    $grubLabel.AutoSize    = $true

    $global:grubStatus = New-Object system.Windows.Forms.Label
    $grubStatus.text        = "To Do"
    $grubStatus.AutoSize    = $true

    $statusPanel.controls.add($grubLabel, 0, $row)
    $statusPanel.controls.add($grubStatus, 1, $row)
    $row++

    $rebootLabel             = New-Object system.Windows.Forms.Label
    $rebootLabel.text        = "Reboot"
    $rebootLabel.AutoSize    = $true

    $global:rebootStatus = New-Object system.Windows.Forms.Label
    $rebootStatus.text        = "To Do"
    $rebootStatus.AutoSize    = $true

    $statusPanel.controls.add($rebootLabel, 0, $row)
    $statusPanel.controls.add($rebootStatus, 1, $row)
    $row++

    $progress.controls.add($statusPanel)

    #TODO: button panel - Abort
    $progress.controls.add( (New-Object system.Windows.Forms.Label) )

    $form.controls.add($progress)


    # Actions

    $form.add_shown({
        $global:main.enabled = $false
        try {
            initFields
        } finally {
            $global:main.enabled = $true
        }
        $linuxSize.focus()
    })
    
    $cleanButton.add_click({
        $global:main.enabled = $false
        try {
            start-process cleanmgr -wait
            calcGui
        } finally {
            $global:main.enabled = $true
        }
    })

    $defragButton.add_click({
        $global:main.enabled = $false
        try {
            start-process dfrgui -wait
            calcGui
        } finally {
            $global:main.enabled = $true
        }
    })

    $parterButton.add_click({
        $global:main.enabled = $false
        try {
            start-process diskmgmt.msc -wait
            calcGui
        } finally {
            $global:main.enabled = $true
        }
    })

    $abortButton.add_click( {
        $form.close()
    })

    $installButton.add_click({
        if( (checkFields) ) {
            $global:main.visible = $false
            $global:progress.visible = $true
            #TODO: Run as PSJob, remove doevents
            [System.Windows.Forms.Application]::DoEvents() 

            $global:defragStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            defrag
            $global:defragStatus.text = 'Done'

            $global:partStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            repartition
            $global:partStatus.text = 'Done'

            $global:dlStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            downloadIso
            $global:dlStatus.text = 'Done'

            $global:grubStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            installGrub
            $global:grubStatus.text = 'Done'

            $global:rebootStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents() 
            Restart-Computer
        }
    })

    return $form
}


$op = $args[0]

switch($op) {
    {$_ -eq "download-iso" } {
        downloadIso
    }
    {$_ -eq "enable-swap" } {
        enableSwap
        Restart-Computer
    }
    {$_ -eq "disable-swap" } {
        disableSwap
        Restart-Computer
    }
    {$_ -eq "tz" } {
#        getLinuxTimezone
        installGrub
    }
    {$_ -eq "defrag" } {
        defrag
    }
    {$_ -eq "preseed" } {
        set-content -value (expandTemplate "files\preseed.cfg") -path "preseed.tmp.cfg"
        get-content -path 'preseed.tmp.cfg'
    }
    default {
        $form = (gui)
        $form.showDialog()
    }
}

