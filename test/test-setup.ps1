# Configure VM for testing purposes

#TODO: create test VM
# download microsoft VM, unzip, del .zip
# create VM
# 3GB, 1 CPU
# share home

# SSH

Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
# Get-NetFirewallRule -Name *ssh*
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Chocolatey install
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y curl
choco install -y unetbootin
choco install -y virtualbox-guest-additions-guest.install

# Convert to EFI
mbr2gpt /validate /allowfullos
mbr2gpt /convert /allowfullos

#TODO: convert VM to EFI
