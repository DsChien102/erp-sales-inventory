@echo off
REM Backward-compatible alias → scripts\env\vet45.bat
call "%~dp0vet45.bat" %*
exit /b %ERRORLEVEL%
