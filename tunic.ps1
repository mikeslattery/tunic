# Tunic Linux Installer for Windows
# Copyright (c) Michael Slattery under GPLv3 with NO warranty.
# For more info see  https://www.gnu.org/licenses/gpl-3.0.html#section15

# Automated install of an iso_path

if( $args[0] -eq 'noop') { exit } # for syntax checking

$global:shim_url = 'https://github.com/pop-os/iso/blob/master/data/efi/shimx64.efi.signed?raw=true'
$global:grubx64_url = 'http://archive.ubuntu.com/ubuntu/pool/main/g/grub2-signed/grub-efi-amd64-signed_1.93.15+2.02-2ubuntu8.14_amd64.deb'

$global:letter = $env:HOMEDRIVE[0]
$global:root_dir="${letter}:"
$global:tunic_dir="${env:ALLUSERSPROFILE}\tunic"

$global:MIN_DISK_GB = 15

$DUALBOOT = 1
$FULLBOOT = 2
$CUSTOMBOOT = 3

# Do very basic initialization

function initData() {
    if( $PSScriptRoot ) {
        set-location -path $PSScriptRoot
    }

    if ( -not (Test-Path "$global:tunic_dir") ) {
        mkdir "$global:tunic_dir" | out-null
    }

    # Load distros from config file
    $global:distros = . files/distros.ps1

    # Load distro information from Downloads directory
    $mounts = ( dir "${HOME}\Downloads\*.iso" | mount-diskImage )
    try {
        if( $mounts ) {
            $global:distros += ( $mounts | % { @{ name=($_ | get-volume).fileSystemLabel; url=$_.imagePath; } } )
        }
    }
    catch {
        write-host $_
    }
    finally {
        $mounts | dismount-diskimage | out-null
    }

    # User account
    $userInfo = ( Get-WMIObject Win32_UserAccount | where caption -eq (whoami) )
    $global:data = @{
        installType = $DUALBOOT;
        fullname = $userInfo.fullName;
        username = $userInfo.name.toLower();
        hostname = $userInfo.psComputerName;
        iso_url  = $global:distros[0].url
    }
}

# Get the name part of an URL
function getUrlFile($url) {
    return $url -replace '^.*/', '' -replace '[?#].*$', ''
}

# Get the path on the disk to the file
function getUrlFilepath($url) {
    $file = getUrlFile($url)

    $dir = "${HOME}\Downloads"
    if ( -not (Test-Path "$dir") ) {
        mkdir "$dir"
    }

    return "${dir}\${file}"
}

# Convert C: file path to grub path.
function getGrubPath($filename) {
    $filename -replace '^.*:', '' -replace '\\', '/'
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

function clean() {
    $regkey = 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    Get-childItem -path $regkey | new-itemproperty -name 'StateFlags0112' -propertytype DWORD -value 2 -force
    start-process cleanmgr /sagerun:112 -wait
}

function defrag() {
    powercfg.exe /h off
    REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
    Optimize-Volume -DriveLetter $global:letter -Defrag
    #TODO: powercfg.exe /h on - if was on before
}

function ternary($expr, $ontrue, $onfalse) {
    if($expr) { return $ontrue } else { return $onfalse }
}

function die($msg) {
    write-host $msg
    [System.Windows.Forms.Messagebox]::Show($msg)
    exit 1
}

function say($msg) {
    write-host $msg
    [System.Windows.Forms.Messagebox]::Show($msg)
}

function yes($q) {
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    return [System.Windows.Forms.MessageBox]::Show($q,"Tunic", $buttons ) -eq "Yes"
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

    $osversion = [System.Environment]::OSVersion.version
    if( $osversion.major -lt 6 -or ($osversion.major -eq 6 -and $osversion.minor -eq 0 ) ) {
        # Windows 7 = 6.1
        die( 'Only Windows 7 or later supported' )
    }

    if( [System.Environment]::Version.major -lt 3 ) {
        die( 'Powershell 3 or above required' )
    }

    if( (Get-WmiObject Win32_Battery).batteryStatus -eq 1 ) {
        die( 'It is too risky to use Tunic while on battery.' )
    }

    if( (New-Object -ComObject 'Microsoft.Update.Installer').isBusy ) {
        die('A Windows Update is in progress.  Try again later.')
    }

    $partc = ( get-partition -driveLetter $global:letter )
    if( (get-disk -number $partc.diskNumber).partitionStyle -eq 'MBR' ) {
        mbr2gpt /validate /allowfullos > $null 2> $null
        if( $? ) {
            if( yes('UEFI required.  Conversion requires BIOS change during boot.  Convert from MBR to UEFI now?') ) {
                mbr2gpt /convert /allowfullos > $null 2> $null
                if( $? ) {
                    restart-computer -force
                } else {
                    die('Could not convert to UEFI.')
                }
            } else {
                die('UEFI required.  Tunic can not run.')
            }
        } else {
            die('UEFI required, but system cannot e converted.')
        }
    }

    $blInfo = Get-Bitlockervolume
    if( $blInfo.ProtectionStatus -eq 'On' ) {
        $recoveryKey = (Get-BitLockerVolume -MountPoint 'C').KeyProtector
        say( "Bitlocker may have issues with dual boot.  Write down your recovery key: $recoveryKey" )
    }
}

function downloadIso() {
    #TODO: remove.  guiDownloadIso w/callback
    $iso_path = getUrlFilepath($global:data.iso_url)
    $iso_file = getUrlFile($global:data.iso_url)
    if ( -not (Test-Path "$iso_path") ) {
        $ciso = "Z:\Downloads\$iso_file"
        if ( Test-Path "$ciso" ) {
            copy "$ciso" "$iso_path"
        } else {
            try {
                (New-Object System.Net.WebClient).DownloadFile($global:data.iso_url, "$iso_path")
            } catch {
                write-host "Error downloading $( $global:data.iso_url ) to $iso_path"
                write-host $_
                Remove-Item "$iso_path"
                Throw "Download failed"
            }
        }
    }
}

function guiDownloadIso() {
    #TODO: save to temp and move after.
    #TODO: verify integrity
    $iso_path = getUrlFilepath($global:data.iso_url)
    $iso_file = getUrlFile($global:data.iso_url)
    if ( -not (Test-Path "$iso_path") ) {
        $ciso = "Z:\Downloads\$iso_file"
        if ( Test-Path "$ciso" ) {
            copy "$ciso" "$iso_path"
        } else {
            Import-Module BitsTransfer
            $url = $global:data.iso_url

            $bits = ( Start-BitsTransfer -DisplayName $url -Source $url -Destination $iso_path -Asynchronous )
            try {
                #TODO: use a callback instead of direct updates.
                $global:dlStatus.text = 'Connecting...'
                While ($Bits.JobState -eq "Connecting") {
                    sleep 1
                    [System.Windows.Forms.Application]::DoEvents()
                }
                $global:dlStatus.text = 'Transferring...'
                While ($Bits.JobState -eq "Transferring" -and $Bits.BytesTransferred -lt ( 1GB / 100 ) ) {
                    sleep 1
                    [System.Windows.Forms.Application]::DoEvents()
                }
                While ($Bits.JobState -eq "Transferring") {
                    if ($Bits.JobState -eq "Error"){
                        Resume-BitsTransfer -BitsJob $Bits
                    }
                    $state = $bits.jobState
                    $pct = [int](($Bits.BytesTransferred*100) / $Bits.BytesTotal)
                    $global:dlStatus.text = "$pct% complete"
                    sleep 1
                    [System.Windows.Forms.Application]::DoEvents()
                }
                #TODO: save to temp and move after.
                #TODO: verify integrity
            } catch {
                write-host "Error downloading $url to $iso_path"
                write-host $_
                Remove-Item "$iso_path"
                Throw "Download failed"
            }
            finally {
                $Bits | Complete-BitsTransfer
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
        if( ! $ltz ) {
            $ltz = $zones[0].type
        }
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

    $secureBootEnabled = $false
    try {
        $secureBootEnabled = (confirm-secureBootUefi)
    } catch {}

    $grub_dir="\boot\grub"
    $grub_path="${efi}${grub_dir}"

    if ( -not (Test-Path "$grub_path\grub.var.cfg") ) {
        $iso_path = getUrlFilepath($global:data.iso_url)
        $iso_grub_path = getGrubPath($iso_path)

        # Install 7z, if needed
        $7z = '7z.exe'
        if( (get-command "7z" -errorAction silentlyContinue).count -eq 0 ) {
            (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z1900.exe', "$env:TEMP\7zi.exe")
            start-process "$env:TEMP\7zi.exe" /S -wait
            remove-item -path "$env:TEMP\7zi.exe" -errorAction silentlyContinue
            $7z = 'C:\Program Files (x86)\7-Zip\7z.exe'
        }

        # Extract grub files
        mkdir "$grub_path" -force | out-null
        & "$7z" x -r "$iso_path" boot\grub "-o$efi\" -y -bb0 > $null
        # grubx64.efi
        (New-Object System.Net.WebClient).DownloadFile($global:grubx64_url, "$env:TEMP\signed.deb")
        & "$7z" e -y "$env:TEMP\signed.deb" "-o${env:TEMP}" > $null
        & "$7z" e -y "$env:TEMP\data.tar" .\usr\lib\grub\x86_64-efi-signed\gcdx64.efi.signed "-o${env:TEMP}" > $null
        move "${env:TEMP}\gcdx64.efi.signed" "${efi}\EFI\BOOT\grubx64.efi" -force
        rm "${env:TEMP}\signed.deb"
        rm "${env:TEMP}\data.tar"
        # shim64.efi
        if( $secureBootEnabled ) {
            (New-Object System.Net.WebClient).DownloadFile($shim_url, "${efi}\EFI\BOOT\shimx64.efi")
        }
        # config
        move "$grub_path\grub.cfg" "$grub_path\grub.orig.cfg" -errorAction silentlyContinue
        copy "files\grub.cfg" "$grub_path\."
        set-content -path "$grub_path\grub.var.cfg" -value "set iso_path='$iso_grub_path'"
    }

    if ( -not (Test-Path "${global:tunic_dir}\bcd-before.bak" ) ) {
        bcdedit /export "${global:tunic_dir}\bcd-before.bak" | out-null
    }

    # Boot Entry
    #TODO: idempotent
    if( test-path("${global:tunic_dir}\bcd.id") ) {
        $osloader = (get-content "${global:tunic_dir}\bcd.id")
        bcdedit /delete "$osloader" /f | out-null
    }
    $osloader = (bcdedit /copy '{bootmgr}' /d ubuntu).replace('The entry was successfully copied to ','').replace('.','')
    bcdedit /set         "$osloader" device "partition=$efi" | out-null
    if( $secureBootEnabled ) {
        bcdedit /set         "$osloader" path "\EFI\BOOT\shimx64.efi" | out-null
    }
    else {
        bcdedit /set         "$osloader" path "\EFI\BOOT\grubx64.efi" | out-null
    }
    bcdedit /set         "$osloader" description "Tunic Linux Installer" | out-null
    bcdedit /deletevalue "$osloader" locale | out-null
    bcdedit /deletevalue "$osloader" inherit | out-null
    bcdedit /deletevalue "$osloader" default | out-null
    bcdedit /deletevalue "$osloader" resumeobject | out-null
    bcdedit /deletevalue "$osloader" displayorder | out-null
    bcdedit /deletevalue "$osloader" toolsdisplayorder | out-null
    bcdedit /deletevalue "$osloader" timeout | out-null
    bcdedit /set '{fwbootmgr}' displayorder "$osloader" /addfirst | out-null
    set-content -path "${global:tunic_dir}\bcd.id" -value "$osloader"

    # Preseed
    set-content -value (expandTemplate "files\preseed.cfg") -path "${global:tunic_dir}\preseed.cfg"

    mountvol $efi /d

    bcdedit /export "${global:tunic_dir}\bcd-grub.bak" | out-null
}

# Calculates globals gap and maxAvailable
function calcPartition() {
    $letter = $global:letter
    $global:partc = (get-partition -driveletter $letter)
    $disk = (get-disk -number $global:partc.diskNumber)

    # Calculate Gap
    $partnext = (get-partition -disknumber $global:partc.disknumber | where-object { $_.partitionNumber -eq ($global:partc.partitionNumber + 1)})
    if( ! $partnext ) {
        #TODO: figure out why -1MB needed
        $global:gap = $disk.size - ( $global:partc.offset + $global:partc.size ) - 1MB
    } else {
        $global:gap = $partnext.offset - ( $global:partc.offset + $global:partc.size )
    }

    # Calculate available
    $global:maxAvailable = $global:partc.size - (get-partitionsupportedsize -driveletter "$letter").sizeMin + $global:gap

}

function repartition() {
    $letter = $global:letter
    $global:partc = (get-partition -driveletter $letter)

    # size entered in GUI
    $linusSizeNum = $global:data.linuxSize * 1GB

    $shrinkBy = $linuxSizeNum - $global:gap

    $newSize = $global:partc.size - ( $shrinkBy )

    if( $shrinkBy -gt 0 ) {
        resize-partition -driveletter $letter -size $newSize
    }
}

function calcGui() {
    $global:form.activate()
    [System.Windows.Forms.Application]::DoEvents()

    calcPartition

    $letter = $global:letter
    $volume = (Get-Volume -driveletter $letter)

    $total = [math]::round( $volume.size / 1GB )
    $free  = [math]::round( $volume.sizeremaining / 1GB )
    $used  = [math]::round( ( $volume.size - $volume.sizeRemaining ) / 1GB )
    $avail = [math]::floor( $global:maxAvailable / 1GB )

    $global:sizeGroup.text  = "${letter}: Drive"

    $global:totalValue.text = "$total GB"
    $global:freeValue.text  = "$free GB"
    $global:usedValue.text  = "$used GB"
    $global:availValue.text = "$avail GB"

    if( ! $global:linuxSize.text ) {
        $global:linuxSize.text = "$(( [math]::max( $global:MIN_DISK_GB, [math]::min( [math]::floor($total / 2) , $avail ) ) ))"
    }
}

function treeMap() {
    $tree_dl='https://windirstat.mirror.wearetriple.com//wds_current_setup.exe'
    $tree_setup= "$($global:tunic_dir)\windirstat-setup.exe"
    $tree_exe= "C:\Program Files (x86)\WinDirStat\windirstat.exe"
    if ( -not (Test-Path "$tree_exe") ) {
        (New-Object System.Net.WebClient).DownloadFile($tree_dl, $tree_setup)
        start-process $tree_setup /S -wait
    }
    start-process "$tree_exe" -wait
}

function initFields() {
    checks
    initData

    $fullname.text = $global:data.fullname
    $username.text = $global:data.username
    $hostname.text = $global:data.hostname

    $distroName.items.addRange( ( $global:distros | % { $_.name } ) )
    $distroName.selectedIndex = 0
}

function checkFields() {
    $global:outer.enabled = $false

    if( $password.text.length -eq 0 ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Password required.")
        $global:outer.enabled = $true
        [Void]$global:password.focus()
        return $false
    }

    if( $global:password.text -ne $global:password2.text ) {
        [Void][System.Windows.Forms.Messagebox]::Show("Passwords don't match")
        $global:outer.enabled = $true
        [Void]$global:password.focus()
        return $false
    }

    if( ! $global:agreeBox.checked ) {
        [Void][System.Windows.Forms.Messagebox]::Show("You must agree to terms to continue.")
        $global:outer.enabled = $true
        [Void]$global:agreeBox.focus()
        return $false
    }

    if( $global:dualBootRadio.checked -and $global:dual.visible ) {
        $linuxSizeNum = [double]::parse( $global:linuxSize.text ) * 1GB
        if( $linuxSizeNum -lt $global:MIN_DISK_GB * 1GB ) {
            [Void][System.Windows.Forms.Messagebox]::Show("Linux requires at least ${MIN_DISK_GB}GB")
            $global:outer.enabled = $true
            [Void]$global:linuxSize.focus()
            return $false
        }

        if( $linuxSizeNum -gt $global:maxAvailable ) {
            [Void][System.Windows.Forms.Messagebox]::Show("Not enough available space.")
            $global:outer.enabled = $true
            [Void]$global:linuxSize.focus()
            return $false
        }
    }

    $global:outer.enabled = $true
    return $true
}

function installTypeCheck() {
    if( $global:dualBootRadio.checked ) {
        $global:installButton.text = 'Continue'
    }
    else {
        $installButton.text = 'Install Now'
    }
}

function gui() {

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $global:Form            = New-Object system.Windows.Forms.Form
    $Form.text              = "Tunic Linux Installer"
    $Form.autosize          = $true

    # Outer layout
    $global:outer = New-Object system.Windows.Forms.TableLayoutPanel
    $outer.autosize          = $true
    $outer.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $outer.columnCount       = 1

    # Main Input Panel
    $global:main = New-Object system.Windows.Forms.TableLayoutPanel
    $main.autosize          = $true
    $main.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $main.padding           = 10
    $main.columnCount       = 1

    $bootGroup              = New-Object system.Windows.Forms.GroupBox
    $bootGroup.text         = "Installation Type"
    $bootGroup.Dock              = [System.Windows.Forms.DockStyle]::Fill

    $bootPanel = New-Object system.Windows.Forms.TableLayoutPanel
    $bootPanel.autosize          = $true
    $bootPanel.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $bootPanel.columnCount       = 1

    $global:dualBootRadio          = New-Object system.Windows.Forms.RadioButton
    $dualBootRadio.text     = "Install Linux alongside Windows"
    $dualBootRadio.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $dualBootRadio.checked  = $true
    $bootPanel.controls.add($dualBootRadio)

    $global:fullBootRadio          = New-Object system.Windows.Forms.RadioButton
    $fullBootRadio.text     = "Erase entire disk and install Linux"
    $fullBootRadio.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $bootPanel.controls.add($fullBootRadio)

    $global:customBootRadio        = New-Object system.Windows.Forms.RadioButton
    $customBootRadio.text   = "Custom/Advanced"
    $customBootRadio.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $bootPanel.controls.add($customBootRadio)

    $bootGroup.controls.add($bootPanel)

    $main.controls.add($bootGroup)

    $distroPanel              = New-Object system.Windows.Forms.TableLayoutPanel
    $distroPanel.autosize     = $true
    $distroPanel.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $distroPanel.padding      = 5
    $distroPanel.columnCount  = 2
    $row = 0

    $distroLabel             = New-Object system.Windows.Forms.Label
    $distroLabel.text        = "Distro"
    $distroLabel.AutoSize    = $true

    $global:distroName = New-Object system.Windows.Forms.ComboBox
    $distroName.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $distroName.width       = 180
    $distroName.AutoSize    = $true

    $distroPanel.controls.add($distroLabel, 0, $row)
    $distroPanel.controls.add($distroName,  1, $row)
    $row++

    $main.controls.add($distroPanel)

    $global:sizeGroup              = New-Object system.Windows.Forms.GroupBox
    $sizeGroup.text         = "C: Drive"
    $sizeGroup.autosize     = $true
    $sizeGroup.Dock              = [System.Windows.Forms.DockStyle]::Fill

    $SizePanel              = New-Object system.Windows.Forms.TableLayoutPanel
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

    $idGroup                    = New-Object system.Windows.Forms.GroupBox
    $idGroup.text               = "Identifcation"
    $idGroup.AutoSize           = $true
    $idGroup.Dock              = [System.Windows.Forms.DockStyle]::Fill

    $idPanel                         = New-Object system.Windows.Forms.TableLayoutPanel
    $idPanel.autosize     = $true
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

    $idGroup.controls.add($idPanel)
    $main.controls.add($idGroup)

    $global:agreeBox = New-Object system.Windows.Forms.CheckBox
    $agreeBox.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $agreeBox.text              =
        "I understand this software could cause data loss " +
        "and is provided as-is without any warranty.  " +
        "I shall not hold the authors liable for any damages whatsoever."
    $agreeBox.AutoSize               = $false
    $agreeBox.height = 50

    $main.controls.add($agreeBox)

    $outer.controls.add($main)

    # Dual boot Input Panel
    $global:dual = New-Object system.Windows.Forms.TableLayoutPanel
    $dual.autosize          = $true
    $dual.Dock              = [System.Windows.Forms.DockStyle]::Fill
    $dual.padding           = 10
    $dual.columnCount       = 1
    $dual.visible           = $false

    $sizeGroup.controls.add($sizePanel)
    $dual.controls.add($sizeGroup)

    $cleanNotice             = New-Object system.Windows.Forms.Label
    $cleanNotice.text        = 'These buttons may help free up more available space'
    $cleanNotice.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $cleanNotice.autoSize    = $false
    $dual.controls.add($cleanNotice)

    $cleanPanel                     = New-Object system.Windows.Forms.FlowLayoutPanel
    $cleanPanel.padding      = 5
    $cleanPanel.Dock         = [System.Windows.Forms.DockStyle]::Fill
    $cleanPanel.AutoSize               = $false

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

    $swapButton                   = New-Object system.Windows.Forms.Button
    $swapButton.text              = "Disable Swap"
    $swapButton.tabStop           = $false
    $cleanPanel.controls.add($swapButton)

    $treeButton                   = New-Object system.Windows.Forms.Button
    $treeButton.text              = "Disk Use"
    $treeButton.tabStop           = $false
    $cleanPanel.controls.add($treeButton)

    $dual.controls.add($cleanPanel)

    $outer.controls.add($dual)

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

    $outer.controls.add($progress)

    # Button Panel - common to all input panels, but not progress

    $buttonPanel                     = New-Object system.Windows.Forms.FlowLayoutPanel
    $buttonPanel.padding      = 5
    $buttonPanel.AutoSize               = $true

    $global:abortButton              = New-Object system.Windows.Forms.Button
    $abortButton.text                = "Quit"
    $abortButton.tabStop           = $false
    $abortButton.dialogResult        = [System.Windows.Forms.DialogResult]::Cancel
    $buttonPanel.controls.add($abortButton)

    $global:installbutton = New-Object system.Windows.Forms.Button
    $installbutton.text              = "Continue"
    $buttonPanel.controls.add($installButton)

    $outer.controls.add($buttonPanel)

    # The main form

    $form.controls.add($outer)

    # Actions

    $form.add_shown({
        $global:outer.enabled = $false
        try {
            initFields
        } finally {
            $global:outer.enabled = $true
        }
        $global:form.activate()
        $dualBootRadio.focus()
    })

    $cleanButton.add_click({
        $global:outer.enabled = $false
        try {
            clean
            calcGui
        } finally {
            $global:outer.enabled = $true
        }
    })

    $defragButton.add_click({
        $global:outer.enabled = $false
        try {
            start-process dfrgui -wait
            calcGui
        } finally {
            $global:outer.enabled = $true
        }
    })

    $parterButton.add_click({
        $global:outer.enabled = $false
        try {
            start-process diskmgmt.msc -wait
            calcGui
        } finally {
            $global:outer.enabled = $true
        }
    })

    $swapButton.add_click({
        $global:outer.enabled = $false
        try {
            #TODO: change button caption disable/enable.
            disableSwap
            if( yes('Swap will be disabled on reboot.  Reboot now?') ) {
                restart-computer -force
            }
        } finally {
            $global:outer.enabled = $true
        }
    })

    $treeButton.add_click({
        $global:outer.enabled = $false
        try {
            treeMap
            calcGui
        } finally {
            $global:outer.enabled = $true
        }
    })

    $global:dualBootRadio.add_click({
        installTypeCheck
    })

    $global:fullBootRadio.add_click({
        installTypeCheck
    })

    $global:customBootRadio.add_click({
        installTypeCheck
    })

    $installButton.add_click({
        $global:data.username = $username.text
        $global:data.fullname = $fullname.text
        $global:data.hostname = $hostname.text
        $global:data.password = $password.text
        if( $dualBootRadio.checked ) {
            $global:data.installType = $DUALBOOT
        } elseif( $fullBootRadio.checked ) {
            $global:data.installType = $FULLBOOT
        } else {
            $global:data.installType = $CUSTOMBOOT
        }
        $global:data.iso_url = $global:distros[ $distroName.selectedIndex ].url

        if( -not (checkFields) ) {
            return
        }
        if( $main.visible -and $dualBootRadio.checked ) {
            $main.visible = $false
            $dual.visible = $true
            $outer.enabled = $false
            try {
                $global:installButton.text = 'Install'
                [System.Windows.Forms.Application]::DoEvents()
                calcGui
            } finally {
                $outer.enabled = $true
            }
            $linuxsize.focus()
        }
        else {
            $global:main.visible = $false
            $global:dual.visible = $false
            $installButton.visible = $false
            $global:progress.visible = $true
            #TODO: Run as PSJob, remove doevents, don't hide abortButton
            $global:abortButton.visible = $false

            if( $global:data.installType -eq $DUALBOOT ) {
                $global:data.linuxSize = [double]::parse( $global:linuxSize.text )

                $global:defragStatus.text = 'In Progress'
                [System.Windows.Forms.Application]::DoEvents()
                defrag
                $global:defragStatus.text = 'Done'

                $global:partStatus.text = 'In Progress'
                [System.Windows.Forms.Application]::DoEvents()
                repartition
                $global:partStatus.text = 'Done'
            } else {
                $global:defragStatus.text = 'Skipped'
                $global:partStatus.text = 'Skipped'
            }

            $global:dlStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents()
            guiDownloadIso
            $global:dlStatus.text = 'Done'

            $global:grubStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents()
            installGrub
            $global:grubStatus.text = 'Done'

            $global:rebootStatus.text = 'In Progress'
            [System.Windows.Forms.Application]::DoEvents()
            Restart-Computer -force
        }
    })

    return $form
}

# Installs full disk install.
# Mainly for testing purposes.
# User will have 'tunic' password.
function fullDisk() {
    initData
    $global:data.installType = $FULLBOOT
    $global:data.password = 'tunic'
    # copied from distros.ps1
    $url = 'http://releases.ubuntu.com/18.04.3/ubuntu-18.04.3-desktop-amd64.iso'
    $url = 'http://releases.ubuntu.com/19.10/ubuntu-19.10-desktop-amd64.iso'
    $url = 'http://mirrors.gigenet.com/linuxmint/iso/stable/19.3/linuxmint-19.3-xfce-64bit.iso'
    $global:data.iso_url = $url

    if( $global:data.installType -eq $DUALBOOT ) {
        write-host 'Defragmenting...'
        defrag
        write-host 'Repartitioning...'
        calcPartition
        repartition
    }

    write-host 'Downloading...'
    downloadIso
    write-host 'Installing Grub...'
    installGrub
    write-host 'Restarting...'
    restart-computer -force
}

$op = $args[0]

switch($op) {
    {$_ -eq "download-iso" } {
        downloadIso
    }
    {$_ -eq "enable-swap" } {
        enableSwap
    }
    {$_ -eq "disable-swap" } {
        disableSwap
    }
    {$_ -eq "install-grub" } {
        downloadIso
        installGrub
    }
    {$_ -eq "tz" } {
        getLinuxTimezone
    }
    {$_ -eq "full-disk" } {
        fullDisk
    }
    {$_ -eq "defrag" } {
        defrag
    }
    {$_ -eq "preseed" } {
        set-content -value (expandTemplate "files\preseed.cfg") -path "preseed.tmp.cfg"
        get-content -path 'preseed.tmp.cfg'
        rm 'preseed.tmp.cfg'
    }
    default {
        $global:form = (gui)
        [void]$form.showDialog()
    }
}

