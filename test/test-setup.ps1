# Configure VM for testing purposes

# Parts were copied from ./tunic.ps1


If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host 'Escalating'
    # Relaunch as an elevated process:
    Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}

Write-host "Started."
$iso_url='http://mirrors.kernel.org/linuxmint/stable/19.2/linuxmint-19.2-cinnamon-64bit.iso'

$letter = $env:HOMEDRIVE[0]
$tunic_dir="${env:ALLUSERSPROFILE}\tunic"
$iso = "${tunic_dir}\linux.iso"
# This is for testing only, so s'ok
$user = 'IEUser'
$password='Passw0rd!'

# Disable Auto Updates

$WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$AutoUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
 
Remove-Item -Path $WindowsUpdatePath -Recurse -errorAction ignore

New-Item -Path $WindowsUpdatePath
New-Item -Path $AutoUpdatePath

Set-ItemProperty -Path $AutoUpdatePath -Name NoAutoUpdate -Value 1

# Disable Defender

New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name DisableAntiSpyware -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet" -Name SpyNetReporting -Value 0 -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet" -Name SubmitSamplesConsent -Value 2 -Force

# Disable Telemetry

Set-Service -Name DiagTrack -StartupType Disabled
Set-Service -Name dmwappushservice -StartupType Disabled
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -Value 1 -Force
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask
New-Item "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl" -ItemType File -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -Value 1 -Force
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Value 0 -Force
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\EnableWebContentEvaluation" -Name Enabled -Value 0 -Force
New-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name HttpAcceptLanguageOptOut -Value 1 -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds -Value 0 -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod -Value 0 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name AutoConnectAllowedOEM -Value 0 -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\MRT" -Name DontReportInfectionInformation -Value 1 -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Value 0 -Force

# Disable Cortana

$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"     
IF(!(Test-Path -Path $path)) {  
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search" 
}  
Set-ItemProperty -Path $path -Name "AllowCortana" -Value 1 
New-NetFirewallRule -DisplayName "Block Cortana Web Access" -Direction Outbound -Program "%windir%\systemapps\Microsoft.Windows.Cortana_cw5n1h2txyewy\SearchUI.exe" -Action Block

# Auto Login

$loginPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
#TODO: next line said alread exists
New-ItemProperty -Path "$loginPath" -Name AutoAdminLogon  -Value 1 -force
New-ItemProperty -Path "$loginPath" -Name DefaultUserName -Value "$user" -force
New-ItemProperty -Path "$loginPath" -Name DefaultPassword -Value "$password" -force

# DNS

#TODO: $gateway = (Get-NetIPConfiguration).ipv4defaultgateway.nexthop
#TODO: add-content 'C:\Windows\System32\drivers\etc\hosts' "$gateway mirrors.kernel.org"

# Desktop Icons

copy "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk" ~/Desktop/.

# Stay Awake

$personalPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
New-Item         -Path "$personalPath" -errorAction ignore
New-ItemProperty -Path "$personalPath" -Name NoLockScreen -Value 1 -force

powercfg /change monitor-timeout-ac 0
powercfg /change disk-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# SSH

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
#TODO: Get-NetFirewallRule -Name *ssh*
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "/c" -PropertyType String -Force
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -errorAction ignore

# Chocolatey installs

install-packageprovider -name NuGet -force
$web = (New-Object System.Net.WebClient)
iex $web.DownloadString('https://chocolatey.org/install.ps1')

choco install -y 7zip

# Convert to EFI

mbr2gpt /validate /allowfullos
mbr2gpt /convert /allowfullos

Write-Host 'Done.'

Stop-Computer -force
