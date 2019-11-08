# Re-enable all things clean.ps1 disabled

wmic pagefileset create name="C:\\pagefile.sys"
powercfg /h on
Enable System Restore (desktop Windows only)
Enable-ComputerRestore -Drive C:
wmic computersystem set AutomaticManagedPagefile=True
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=2048,MaximumSize=2048

