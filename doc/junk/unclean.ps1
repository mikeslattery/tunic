# Re-enable all things clean.ps1 disabled

Enable-ComputerRestore -Drive C:
Enable-WindowsErrorReporting

# Enable Swap
wmic pagefileset create name="C:\\pagefile.sys"
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=2048,MaximumSize=2048
wmic computersystem set AutomaticManagedPagefile=True

# Enable Hibernate
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 1 /F
powercfg.exe /h on

