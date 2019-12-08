#!/bin/bash
usage() { cat >&2 <<USAGE
Usage: $0 <subcommand> [<args>]

${docs}
USAGE
}

set -euo pipefail

VMBASE="MSEdge - Win10 - EFI"
VM="${VMBASE} - clone"
SNAPSHOT="test"
SSHPORT=5222
SSHUSER=ieuser
winhome="/c/Users/$SSHUSER"
docs=""
use() { docs="${docs}${1}"$'\n'; }

vboxmanage() {(
    set -x
    VBoxManage -q "$@"
)}

_vmexists() {
    VBoxManage list vms | grep -sq "\"${VM}\""
}
_vmrunning() {
    VBoxManage list runningvms | grep -sq "\"${VM}\""
}

use "stop-vm     Stop running VM"
stop-vm() {
    if _vmrunning; then
        vboxmanage controlvm "$VM" poweroff
        while _vmrunning; do sleep 2; done
        sleep 2
    fi
}

use "delete-vm   Deletes VM"
delete-vm() {
    if _vmexists; then
        vboxmanage unregistervm "$VM" --delete
        vboxmanage snapshot "$VMBASE" delete "$SNAPSHOT"
        while _vmexists; do sleep 2; done
    fi
}

use "create-vm   Creates the test VM '$VM'"
use "            from VM '$VMBASE' snapshot '$SNAPSHOT'"
create-vm() {
    if ! _vmexists; then
        vboxmanage snapshot "$VMBASE" take "$SNAPSHOT"
        vboxmanage clonevm "$VMBASE" --name "$VM" --snapshot "$SNAPSHOT" --options link --register
    fi
}

use "start-vm    Starts the test VM"
start-vm() {
    if ! _vmrunning; then
        vboxmanage startvm "$VM" --type gui
        while ! nc -z localhost "$SSHPORT"; do sleep 2; done
        sleep 10
    fi
    echo 'Started VM.'
}

use "shell       Run a shell command in the VM"
shell() {
    sshpass -p 'Passw0rd!' ssh "$SSHUSER"@localhost -p "$SSHPORT" "$@"
}

power-up() {
    power-down
    create-vm
    start-vm
    shell "$@"
}

use "install-iso   A complete test"
install-iso() {
    #shell 'X: && cd src/tunic && powershell -executionpolicy bypass -command .\install-efi.ps1 && shutdown /r /t 0'
    power-up 'X: && cd src/tunic && powershell -executionpolicy bypass -command .\install-efi.ps1 && shutdown /r /t 0'
}

power-down() {
    stop-vm
    delete-vm
}

loop() {
    power-up
    shell "dir"
    power-down
}

main() {
    [[ "$#" -gt 0 ]] || usage
    "$@" || usage
}

main "$@"

