package main

import (
    "log"
    "net/http"
    "io"
    "os"
    "os/exec"
)

/**
 * Tunic Linux Installer
 *
 * This is just something to get us started with very minimal MVP.
 * The MVP just downloads the old Tunic and runs it.
 */
func Download() error {
    resp, err := http.Get("https://github.com/mikeslattery/tunic/releases/download/0.2.4/tunic.exe")
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    out, err := os.Create("tunic024.exe")
    if err != nil {
        return err
    }
    defer out.Close()

    _, err = io.Copy(out, resp.Body)
    return err
}

func Run() error {
    cmd := exec.Command("tunic024.exe")
    err := cmd.Run()
    return err
}

func main() {
    err := Download()
    if err != nil {
        err = Run()
    }
    if err != nil {
        log.Fatal(err)
        os.Exit(1)
    }
}

