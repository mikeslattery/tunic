$linux_system_size = 40GB
$linux_home_size = 40GB
$letter = $env:HOMEDRIVE[0]

# Defrag
Write-Host "Defragmenting disk..."
Optimize-Volume -DriveLetter $letter -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority

Write-Host "Repartioning disk..."
$linuxsize = $linux_system_size + $linux_home_size
$winsizemin = (get-partitionsupportedsize -driveleter $letter).sizemin
$winfree = (Get-Volume -driveletter $letter).SizeRemaining
$winpart = Get-Partition -DriveLetter $letter
$available = $winpart.size - $winsizemin
$disk = $winpart.disknumber

$memstatus = "$([Math]::Floor($winfree / 1GB)) GB free, $([Math]::Floor($available / 1GB)) GB available."
if( $linuxsize -gt $winfree) { throw "Not enough room. $memstatus" }
if( $linuxsize -gt $available) { throw "Hidden files are in the way. Try to clean and reboot again. $memstatus" }

$winpart | Resize-Partition -Size ( $winpart.size - $linuxsize )
$winpart = Get-Partition -DriveLetter $letter
$linux_system = new-partition -disknumber $disk -offset ( $winpart.offset + $winpart.size ) -size $linux_system_size
$linux_home   = new-partition -disknumber $disk -offset ( $linux_system.offset + $linux_system.size ) -usemaximumsize

Write-Host "Downloading ISO..."
mkdir C:\linux
#TODO: download ISO to C:\linux

Write-Host "Installing VirtualBox..."
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y virtualbox

Write-Host "Creating VM..."
$rawdisk=(get-wmiobject win32_diskdrive -filter "index=${disk}").deviceId
VBoxManage internalcommands createrawvmdk -filename "C:\linux\rawparts.vmdk" -rawdisk "$rawdisk" -relative -partitions $linux_system.partitionnumber,$linux_home.partitionnumber
#TODO: create VM with VBoxManage.   volumn names should match the final names, if possible.
#TODO: automate distro install

# Add to Boot Menu
$parttype = (get-disk -disknumber $disk).partitionstyle
#TODO: download or copy *.efi file to C:\linux
#TODO: use bcdedit commands to add menu item, set timeout value.
#install easybcd, easyuefi for experimentation
#bcdedit /export c:\linux\bcd.bak
#bcdedit /enum firmware
#bcdedit /create /c "Linux Mint" /application ?????
#Returns a value for {ID}
#bcdedit /set {ID} device partition=c:
#bcdedit {ID} PATH \linux\shimx64.efi (or grup4bcd.img)
#bcdedit /displayorder {ID} /addlast
#bcdedit /set {bootmgr} path \EFI\ubuntu\shimx64.efi
#bcdedit /set {bootmgr} path C:\linux\shimx64.efi
