$linux_system_size = 40GB
$linux_home_size = 40GB
$letter = $env:HOMEDRIVE[0]

# TODO: Parameters.
# Separate routine for repart: split c <sys-part-size> <home-part-size>
# Call separate routine for VM installations:
# install-vm c <sys-part> <home-part> [-bootmenu:true]

# TODO: logging functions: format-list *, append, timestamp

Write-Host "Defragmenting disk..."
Optimize-Volume -DriveLetter $letter -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority

$efi = (ls function:[d-z]: -n | ?{ !(test-path $_) } | random)
#TODO: this line failed first time I ran it:
mountvol.exe "$efi" /s
Compress-Archive -Path "$efi" -DestinationPath "C:\linux\efi.zip"
mountvol.exe "$efi" /d

Write-Host "Backing up..."
$efi = (ls function:[d-z]: -n | ?{ !(test-path $_) } | random)
#TODO: this line failed first time I ran it:
mountvol $efi /s
#TODO: ex.txt with BCD,BCD.LOG
xcopy e: c:\linux\efi /s /e /exclude:c:\linux\ex.txt
#TODO: Compress-Archive -Path "$efi" -DestinationPath "C:\linux\efi.zip"
#TODO: cp -r /e /c/linux/efi
mountvol $efi /d
bcdedit /export c:\linux\bcd.bak
#TODO: read MBR
Write-Host "INITIAL" | Out-File -FilePath c:\linux\out.log -Append
Get-ComputerInfo | Out-File -FilePath c:\linux\out.log -Append
bcdedit /enum | Out-File -FilePath c:\linux\out.log -Append
Get-Partition | Out-File -FilePath c:\linux\out.log -Append
Get-Volume | Out-File -FilePath c:\linux\out.log -Append
Get-Disk | Out-File -FilePath c:\linux\out.log -Append

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

Write-Host "Repartition done.  Start of install."

Write-Host "Downloading ISO..."
mkdir C:\linux
$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'
(New-Object System.Net.WebClient).DownloadFile($iso_url, "C:\linux\live.iso")

Write-Host "Installing VirtualBox..."
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y virtualbox

Write-Host "Creating VM..."
$rawdisk=(get-wmiobject win32_diskdrive -filter "index=${disk}").deviceId
#TODO: don't assume EFI is partition 1.  Find by GUID
VBoxManage internalcommands createrawvmdk -filename "C:\linux\rawparts.vmdk" -rawdisk "$rawdisk" -partitions 1,$linux_system.partitionnumber,$linux_home.partitionnumber
#TODO: create VM with VBoxManage.  --firmware efi. volume names should match the final names, if possible.
#TODO:    which video mode
#TODO: use VMBoxManage unattended + preceed.cfg

# Write-Host "Adding to boot menu..."
$parttype = (get-disk -disknumber $disk).partitionstyle
#TODO: download or copy *.efi file to C:\linux
#TODO: use bcdedit commands to add menu item, set timeout value.
#install easybcd, easyuefi for experimentation
#bcdedit /enum firmware
#bcdedit /create /c "Linux Mint" /application ?????
#Returns a value for {ID}
#bcdedit /set {ID} device partition=c:
#bcdedit {ID} PATH \linux\shimx64.efi (or grup4bcd.img)
#bcdedit /displayorder {ID} /addlast
#bcdedit /set {bootmgr} path \EFI\ubuntu\shimx64.efi
#bcdedit /set {bootmgr} path C:\linux\shimx64.efi

Write-Host "FINAL" | Out-File -FilePath c:\linux\out.log -Append
bcdedit /list | Out-File -FilePath c:\linux\out.log -Append
Get-Partition | Out-File -FilePath c:\linux\out.log -Append
Get-Volume | Out-File -FilePath c:\linux\out.log -Append

Write-Host "Complete."

