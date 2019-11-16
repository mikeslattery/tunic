
USER="$(whoami)"
name="Mint2"
password="mike68"
tzone='EST'
country='US'
hostname='hostname'
rawdisk='`\.\PHYSICALDRIVE0'

vboxmanage createvm -name "$name" `
  --ostype Ubuntu_64 `
  --register

vboxmanage modifyvm "$name" `
  --cpus 1 `
  --memory 1024 `
  --vram 12

VBoxManage internalcommands createrawvmdk `
  -filename 'C:`linux\15.vmdk' \
  -rawdisk "$rawdisk" -partitions 1,5

VBoxManage storageattach "$name" `
  --storagectl "IDE Controller" `
  --port 0 --device 0 --type hdd `
  --medium 'C:`linux\15.vmdk'

#TODO: mount iso as .vdi, launch vm w/gui
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
  --iso 'C:`linux\mintcin.iso' \
  --start-vm gui

