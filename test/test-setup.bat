@echo off

cd "%~dp0"

powershell -executionpolicy bypass -nologo -noninteractive -file test-setup.ps1 -args %*
