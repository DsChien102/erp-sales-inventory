@echo off
setlocal
cd /d "%~dp0..\.."
dart run tools\vet45_env\bin\vet45_env.dart %*
