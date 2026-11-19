@echo off
REM Backward-compatible alias → scripts\env\c45.bat
call "%~dp0c45.bat" %*
exit /b %ERRORLEVEL%
