#!/bin/bash
# Tunic Linux Installer for Windows
# Copyright (c) Michael Slattery under GPLv3 with NO warranty.
# For more info see  https://www.gnu.org/licenses/gpl-3.0.html#section15

usage() { cat >&2 <<USAGE
Usage: $0 <subcommand> [<args>]

${docs}
USAGE
}
docs=""; use() { docs="${docs}${1}"$'\n'; }

set -euo pipefail

vm_url='https://az792536.vo.msecnd.net/vms/VMBuild_20190311/VirtualBox/MSEdge/MSEdge.Win10.VirtualBox.zip'
VMBASE="MSEdge - Win10"
VMPARENT="tunic-parent-test"
VM="tunic-test"
SNAPSHOT="init"
SSHPORT=5222
#TODO: remove: SIZE=51200
user=IEUser
password='Passw0rd!'

# Echo commands as they run
se() {(
    set -x
    "$@"
)}

vboxmanage() {(
    set -x
    VBoxManage -q "$@"
)}

_vmexists() {
    vm="${1:-${VM}}"
    VBoxManage -q list vms | grep -sq "\"${vm}\""
}
_vmrunning() {
    vm="${1:-${VM}}"
    VBoxManage -q list runningvms | grep -sq "\"${vm}\""
}

use 'install-tools Install packages required for testing on Ubuntu'
install-tools() {
    sudo apt install -y virtualbox openssh-client
}

use 'build-vm      Create a Windows VM image'
build-vm() {
    echo "This builds 2 VMs:"
    echo "  $VMBASE : The stock one from Microsoft"
    echo "  $VMPARENT : THe parent VM of testing"
    echo "Both will have a snapshoed called $SNAPSHOT"
    echo "When tests are run, a VM named $VM will be created"
    echo ""
    echo 'Building VM...'

    if ! _vmexists "$VMBASE"; then
        echo 'Downloading and extracting VM...'
        if [[ ! -f "${VMBASE}.ova" ]]; then
            se curl -f -o msvbox.tmp.zip -L "$vm_url"
            mv msvbox.zip.tmp msvbox.zip
            se unzip msvbox.zip
            rm msvbox.zip
        fi

        # create new VirtualBox VM
        vboxmanage import "${VMBASE}.ova"
        #TODO: rm "${VMBASE}.ova"
    fi

    # Delete if exists
    if _vmexists "$VMPARENT"; then
        vboxmanage unregistervm "$VMPARENT" --delete
        vboxmanage snapshot "$VMBASE" delete "$SNAPSHOT"
    fi

    # Create $VMPARENT template clone
    vboxmanage snapshot "$VMBASE" take "$SNAPSHOT"
    vboxmanage clonevm  "$VMBASE"  --name "$VMPARENT" --snapshot "$SNAPSHOT" \
        --options link --register
    vboxmanage modifyvm "$VMPARENT" \
        --memory 4096 --cpus 2 \
        --clipboard bidirectional
    vboxmanage modifyvm "$VMPARENT" --natpf1 "guestssh,tcp,,${SSHPORT},,22"
    vboxmanage sharedfolder add "$VMPARENT" --name linux \
        -hostpath "$HOME" -automount

    # Change size
    #TODO: remove: storage="$(vboxmanage showvminfo "$VMPARENT" --machinereadable | grep 'IDE Controller-0-0' | cut -d= -f2 | sed 's/"//g')"
    #TODO: remove: vboxmanage modifymedium disk "$storage" --resize "$SIZE"

    # Run test-setup
    vboxmanage startvm "$VMPARENT" --type gui
    se sleep 10
    while ! VBoxManage guestcontrol "$VMPARENT" run \
        --username "$user" --password "$password" \
        'C:\Windows\System32\cmd.exe' /c -- rem &>/dev/null; do
        se sleep 5
    done
    vboxmanage guestcontrol "$VMPARENT" copyto \
        --username "$user" --password "$password" \
        --target-directory "C:\Users\$user\Desktop" \
        test-setup.ps1
    vboxmanage guestcontrol "$VMPARENT" copyto \
        --username "$user" --password "$password" \
        --target-directory "C:\Users\$user\Desktop" \
        test-setup.bat
    #TODO: run test-setup.ps1 as admin shortcut on desktop

    echo 'VM created.  Now do these steps:'
    echo    '   From the desktop run as administrator test-setup.ps1'
    echo -n '   Hit enter to continue: '
    read -r

    vboxmanage modifyvm "$VMPARENT" --firmware efi
}

use "create-vm     Creates the test VM '$VM'"
use "              from VM '$VMPARENT' snapshot '$SNAPSHOT'"
create-vm() {
    if ! _vmexists; then
        vboxmanage snapshot "$VMPARENT" take "$SNAPSHOT"
        vboxmanage clonevm "$VMPARENT" --name "$VM" --snapshot "$SNAPSHOT" --options link --register
    fi
}

use "delete-vm     Deletes VM"
delete-vm() {
    if _vmexists; then
        vboxmanage unregistervm "$VM" --delete
        vboxmanage snapshot "$VMPARENT" delete "$SNAPSHOT"
        while _vmexists; do sleep 2; done
    fi
}

use "start-vm      Starts the test VM"
start-vm() {
    if ! _vmrunning; then
        vboxmanage startvm "$VM" --type gui
        while ! nc -z localhost "$SSHPORT"; do sleep 2; done
        sleep 25
    fi
    echo 'Started VM.'
}

use "stop-vm       Stop running VM"
stop-vm() {
    if _vmrunning; then
        vboxmanage controlvm "$VM" poweroff
        while _vmrunning; do sleep 2; done
        sleep 2
    fi
}

use "shell         Run a shell command in the VM"
shell() {
    sshpass -p "$password" ssh "$user"@localhost -p "$SSHPORT" "$@"
}

use "power-up      Recycle VM and start shell"
power-up() {
    power-down
    create-vm
    start-vm
    shell "$@"
}

use "power-down    Stop and delete VM"
power-down() {
    stop-vm
    delete-vm
}

mirror() {
    docker run --name nginx \
        -d \
        -p 80:80 \
        -v "$HOME/Downloads:/usr/share/nginx/html/linuxmint/stable/19.3" \
        nginx:alpine
}

use "install-iso   A complete test"
install-iso() {
    #shell 'Z: && cd src/tunic && powershell -executionpolicy bypass -command .\tunic.ps1'
    power-up 'Z: && cd src/tunic && powershell -executionpolicy bypass -command .\tunic.ps1 install'
}

main() {
    [[ "$#" -gt 0 ]] || usage
    "$@" || usage
}

main "$@"

