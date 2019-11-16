Set-ExecutionPolicy Bypass -Scope Process -Force

$USER="${env:USERNAME}"
$name="Mint2"
$password="mike68"
$tzone='EST'
$country='US'
$hostname='hostname'
$rawdisk='\\.\PHYSICALDRIVE0'

VBoxManage createvm -name "$name" `
  --ostype Ubuntu_64 `
  --register

VBoxManage modifyvm "$name" `
  --cpus 1 `
  --memory 1024 `
  --vram 12

# TODO: skip or del file if exists
# TODO: determine efi part#
VBoxManage internalcommands createrawvmdk `
  -filename 'C:\linux\15.vmdk' `
  -rawdisk "$rawdisk" -partitions 1,6

VBoxManage storagectl "$name" `
  --name 'SATA Controller' --add sata `
  --controller IntelAHCI

VBoxManage storageattach "$name" `
  --storagectl 'SATA Controller' `
  --port 0 --device 0 --type hdd `
  --medium 'C:\linux\15.vmdk'

VBoxManage storagectl "$name" `
  --name 'IDE Controller' --add ide

VBoxManage storageattach "$name" `
  --storagectl 'IDE Controller' `
  --port 0 --device 0 --type dvddrive `
  --medium 'C:\linux\mintcin.iso'

#TODO: VBoxManage modifyvm "$name" --ioapic on 
VBoxManage modifyvm "$name" --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage startvm "$name"
exit 0

VBoxManage controlvm "$name" acpipowerbutton

#TODO: unattended w/o harming efi

# [--password-file=file] [--full-user-name=name]
# [--additions-iso=add-iso] [--validation-kit-iso=testing-iso] [--locale=ll_CC]
# [--country=CC] [--time-zone=tz] [--hostname=fqdn] [--package-selection-adjustment=keyword] [--dry-run]
# [--auxiliary-base-path=path] [--image-index=number] [--script-template=file] [--post-install-template=file]
# [--post-install-command=command] [--extra-install-kernel-parameters=params] [--language=lang]
 
vboxmanage unattended install "$name" `
  --user "$USER" --password="$password" `
  --install-additions `
  --time-zone "$tzone" `
  --hostname "$hostname" `
  --country "$country" `
  --iso 'C:\linux\mintcin.iso' `
  --start-vm gui

