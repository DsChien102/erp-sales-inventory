@echo off
setlocal
cd /d "%~dp0..\.."
set "BIN=%CD%\.c45\bin\c45.exe"
if exist "%BIN%" (
  "%BIN%" %*
  exit /b %ERRORLEVEL%
)
echo tip: run `melos run env:build` once for a faster AOT binary (falling back to dart run) 1>&2
dart run tools\c45_env\bin\c45_env.dart %*
exit /b %ERRORLEVEL%
