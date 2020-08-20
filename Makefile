include test.mk

default: utest

tunic.exe: main.go
	GOOS=windows GOARCH=amd64 go build -o tunic.exe

tunic: main.go
	GOOS=linux GOARCH=amd64 go build

# public aliases (phony)

clean:
	go clean
	rm -f tunic.exe tunic

build: tunic.exe tunic

run: main.go
	go run main.go

all: clean unittest tunic tunic.exe

#TODO:
# aliases: https://stackoverflow.com/questions/23135840/alias-target-name-in-makefile/33594470#33594470
#

