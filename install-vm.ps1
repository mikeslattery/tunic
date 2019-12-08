#TODO: params: partitions(1,6), iso

$USER="${env:USERNAME}"
$name="Mint2"
$password="mike68"
$tzone='EST'
$country='US'
$hostname='hostname'
$rawdisk='\\.\PHYSICALDRIVE0'

if ( $(VBoxManage list vms | findstr "$name") ) {
  VBoxManage unregistervm "$name" --delete
}

VBoxManage createvm -name "$name" `
  --ostype Ubuntu_64 `
  --register

VBoxManage modifyvm "$name" `
  --cpus 1 `
  --memory 1024 `
  --vram 12

# TODO: determine efi part#
VBoxManage internalcommands createrawvmdk `
  -filename 'C:\linux\partitions.vmdk' `
  -rawdisk "$rawdisk" -partitions '1,6'

#TODO:
# Convert as if -relative had been passed.
# sed -ri 's/FLAT "\\.\PHYSICALDRIVE[1,6]" [0-9]+$/ZERO/' C:\linux\partitions.vmdk
# sed -ri 's/FLAT "\\.\PHYSICALDRIVE([1-9]+)" [0-9]$/FLAT "\\.\Harddisk0Partition\1" 0/' C:\linux\partitions.vmdk
# unmapped lines will have ZERO$ instead of FLAT.*$
# 1st line is without -relative
# 1st col is size/12.  1st line last col is relative to beginning /512.
#-RW 171911168 FLAT "\\.\PHYSICALDRIVE0" 65820672
#+RW 171911168 FLAT "\\.\Harddisk0Partition6" 0

VBoxManage storagectl "$name" `
  --name 'SATA Controller' --add sata `
  --controller IntelAHCI

VBoxManage storageattach "$name" `
  --storagectl 'SATA Controller' `
  --port 0 --device 0 --type hdd `
  --medium 'C:\linux\partitions.vmdk'

VBoxManage storagectl "$name" `
  --name 'IDE Controller' --add ide

VBoxManage storageattach "$name" `
  --storagectl 'IDE Controller' `
  --port 0 --device 0 --type dvddrive `
  --medium 'C:\linux\mintcin.iso'

#TODO: VBoxManage modifyvm "$name" --ioapic on 
VBoxManage modifyvm "$name" --boot1 dvd --boot2 disk --boot3 none --boot4 none

exit 0
VBoxManage startvm "$name"

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

