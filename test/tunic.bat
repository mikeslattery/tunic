@echo off
cd "%~dp0\.."

rem For testing purposes

powershell -executionpolicy bypass -nologo -noninteractive -file tunic.ps1 %*
