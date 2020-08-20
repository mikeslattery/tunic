download-vm10:
	# Found at https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
	#TODO: https://app.vagrantup.com/Microsoft/boxes/EdgeOnWindows10
	curl -L 'https://az792536.vo.msecnd.net/vms/VMBuild_20190311/VirtualBox/MSEdge/MSEdge.Win10.VirtualBox.zip'
	unzip MSEdge.Win10.VirtualBox.zip
	rm MSEdge.Win10.VirtualBox.zip
	#TODO: create 'MSEdge - Win10.ova'

utest: main.go
	go test

loop:
	# TODO: recusrive on all source input: .go, resources, images, etc
	while :; do inotifywait -qq -r -e create,close_write,modify,move,delete ./ && go test ./...; done

