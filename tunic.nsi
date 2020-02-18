Name "Tunic Linux Installer"
OutFile "tunic.exe"
ShowInstDetails hide
SilentInstall silent
Unicode true
Icon "files\tunic-logo.ico"

!include x64.nsh

Section "Tunic Linux Installer"
    SetOutPath "$TEMP\Tunic"
    file tunic.ps1
    file /r files
    ${If} ${RunningX64}
        ExecWait '$WINDIR\sysnative\windowspowershell\v1.0\powershell.exe -executionpolicy bypass -nologo -inputformat none -noninteractive -WindowStyle Hidden -file tunic.ps1'
    ${Else}
        ExecWait 'powershell.exe -executionpolicy bypass -nologo -inputformat none -noninteractive -WindowStyle Hidden -file tunic.ps1'
    ${EndIf}
SectionEnd

