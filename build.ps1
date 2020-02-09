# Tunic Linux Installer for Windows
# Copyright (c) Michael Slattery under GPLv3 with NO warranty.
# For more info see  https://www.gnu.org/licenses/gpl-3.0.html#section15

# Automated install of an ISO file
# Windows build script

# This is only for packaging a convenient, self-extracting .exe.
# tunic.ps1 is usable without packaging.

# Strict mode

Set-StrictMode -version 1.0
$ErrorActionPreference = 'Stop'

# Install tools

if( ! ( Get-Command "choco" -ErrorAction SilentlyContinue ) ) {
    $web = (New-Object System.Net.WebClient)
    iex $web.DownloadString('https://chocolatey.org/install.ps1')
}

if( ! ( Get-Command "makensis" -ErrorAction SilentlyContinue ) ) {
    choco install -y nsis

    new-alias -name makensis -value 'C:\Program Files (x86)\NSIS\makensis' -force
}

# Syntax check

.\tunic.ps1 noop

# Clean

Remove-Item tunic.exe -ErrorAction Ignore

# Convert tunic.ps1 to tunic.exe

makensis tunic.nsi

