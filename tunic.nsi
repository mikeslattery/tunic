Name "Tunic Linux Installer"
OutFile "tunic.exe"
ShowInstDetails hide
SilentInstall silent
Unicode true
Icon "files\tunic-logo.ico"

Section "Tunic Linux Installer"
    SetOutPath "$TEMP\Tunic"
    file tunic.ps1
    file /r files
    ExecWait 'powershell.exe -executionpolicy bypass -nologo -inputformat none -noninteractive -WindowStyle Hidden -file tunic.ps1 hidden'
SectionEnd

