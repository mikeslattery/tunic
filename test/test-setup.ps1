# Configure VM for testing purposes

# Parts were copied from ./install-efi.ps1

Write-host "Started."

$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$iso = "${tunic_dir}\linux.iso"

#TODO: replace mkdir with better ps command
mkdir "$tunic_dir" -force

if ( -not (Test-Path "$iso") ) {
    Write-host "Downloading ISO... (this takes a long time)"
    try {
        (New-Object System.Net.WebClient).DownloadFile($iso_url, "$iso")
    } catch {
        Remove-Item "$iso"
    }
}

# SSH

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
#TODO: Get-NetFirewallRule -Name *ssh*
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Chocolatey installs
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y curl
choco install -y nsis-advancedlogging
$env:PATH += ";C:\Program Files (x86)\NSIS\Bin"
set /x PATH $env:PATH
choco install -y unetbootin
choco install -y virtualbox-guest-additions-guest.install

# Convert to EFI
mbr2gpt /validate /allowfullos
mbr2gpt /convert /allowfullos

