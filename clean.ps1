# Turn off swap
Write-Host "Cleaning file system..."

$letter = $env:HOMEDRIVE[0]
chkdsk "${letter}:"

# Turn off hibernation and fast start
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
powercfg.exe /h off

# Diable swap
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

# Cleanup
Cleanmgr /sagerun:16
Get-ComputerRestorePoint | Delete-ComputerRestorePoint -WhatIf 
Disable-ComputerRestore -Drive "C:\"
fsutil usn deletejournal /d /n c:
vssadmin delete shadows /all /quiet
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
Disable-WindowsErrorReporting
Clear-WindowsDiagnosticData -Force

#TODO: REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl" /V CrashDumpEnabled /T REG_DWORD /D 0 /F
#TODO: REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting" /v Disabled /T REG_DWORD /D 1 /F

# Defrag
Write-Host "Defragmenting disk..."
Optimize-Volume -DriveLetter $letter -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority

# Reboot is necessary before swap can be deleted.
#TODO: reboot and continue w/o password
Restart-Computer

