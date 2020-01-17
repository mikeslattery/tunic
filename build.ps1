# Windows build script

# This is only for packaging a convenient, self-extracting .exe.
# tunic.ps1 is usable without packaging.

# Install tools

Set-StrictMode -version 1.0
$ErrorActionPreference = 'Stop'

mkdir -force tmp
$web = (New-Object System.Net.WebClient)

if( ! (get-installedmodule -name ps2exe -errorAction silentlyContinue) ) {
    install-packageprovider -name nuget -force
    Install-Module -force -confirm:$false ps2exe
}

if( ! ( Get-Command "7z" -ErrorAction SilentlyContinue ) ) {
    if( ! ( Get-Command "choco" -ErrorAction SilentlyContinue ) ) {
        iex $web.DownloadString('https://chocolatey.org/install.ps1')
    }
    choco install -y 7zip
}

if( ! ( test-path "$PWD\tmp\7zSD.sfx" -errorAction SilentlyContinue) ) {
    $web.downloadFile('https://www.7-zip.org/a/lzma1900.7z', "$PWD\tmp\lzma.7z")
    7z e "$PWD\tmp\lzma.7z" -otmp bin\7zSD.sfx
}

#TODO: remove?
#$web = (New-Object System.Net.WebClient)
#iex $web.DownloadString('https://chocolatey.org/install.ps1')
#choco install -y nsis-advancedlogging
#$env:PATH += ";C:\Program Files (x86)\NSIS\Bin"

function Test-Syntax
{
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='File', Position = 0)]
        [string]$Path, 

        [Parameter(Mandatory=$true, ParameterSetName='String', Position = 0)]
        [string]$Code
    )

    $Errors = @()
    if($PSCmdlet.ParameterSetName -eq 'String'){
        [void][System.Management.Automation.Language.Parser]::`
            ParseInput($Code,[ref]$null,[ref]$Errors)
    } else {
        [void][System.Management.Automation.Language.Parser]::`
            ParseFile($Path,[ref]$null,[ref]$Errors)
    }

    return [bool]($Errors.Count -lt 1)
}

Test-Syntax 'tunic.ps1'

# Clean

Remove-Item tmp\lzma.7z -ErrorAction Ignore
Remove-Item tunic-script.exe -ErrorAction Ignore
Remove-Item tunic.exe -ErrorAction Ignore
Remove-Item tmp\tunic.7z -ErrorAction Ignore

# Convert tunic.ps1 to tunic-script.exe

invoke-ps2exe -inputfile tunic.ps1 -outputfile tunic-script.exe `
    -title Tunic `
    -credentialsGUI -requireAdmin `
    -noconsole -nooutput -noerror

# Package self-extracting .exe

7z a tmp\tunic.7z tunic.ps1 tunic-script.exe files\*

gc -Encoding Byte -Path "tmp\7zSD.sfx","files\7z.conf","tmp\tunic.7z" `
    | sc -Encoding Byte tunic.exe

copy tunic.exe ~\Desktop\tunic.exe

# Clean

Remove-Item tunic-script.exe -ErrorAction Ignore
Remove-Item tmp\tunic.7z -ErrorAction Ignore

