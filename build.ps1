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

function addToPath($dir) {
    $path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
    $path="$path;$dir"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $path

    $env:PATH = "${env:PATH};$dir"
}

if( ! ( Get-Command "choco" -ErrorAction SilentlyContinue ) ) {
    $web = (New-Object System.Net.WebClient)
    iex $web.DownloadString('https://chocolatey.org/install.ps1')
}

if( ! ( Get-Command "makensis" -ErrorAction SilentlyContinue ) ) {
    choco install -y nsis
    addToPath 'C:\Program Files (x86)\NSIS'
}

# Syntax check

.\tunic.ps1 noop

# Clean

Remove-Item tunic.exe -ErrorAction Ignore

# Convert tunic.ps1 to tunic.exe

makensis /V2 tunic.nsi

copy tunic.exe ~/Desktop/. -force

