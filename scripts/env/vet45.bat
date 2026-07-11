@echo off
setlocal
cd /d "%~dp0..\.."
set "BIN=%CD%\.vet45\bin\vet45.exe"
if exist "%BIN%" (
  "%BIN%" %*
  exit /b %ERRORLEVEL%
)
echo tip: run `melos run env:build` once for a faster AOT binary (falling back to dart run) 1>&2
dart run tools\vet45_env\bin\vet45_env.dart %*
exit /b %ERRORLEVEL%
