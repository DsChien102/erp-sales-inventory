@echo off
REM Activate Mosaic Retail env/profile for the current CMD session (like Python venv).
REM
REM Usage:
REM   scripts\env\activate.bat
REM   call scripts\env\activate.bat
REM
REM Deactivate:
REM   deactivate

setlocal EnableExtensions EnableDelayedExpansion

set "C45_SCRIPT_DIR=%~dp0"
REM scripts\env\ -> repo root
for %%I in ("%C45_SCRIPT_DIR%..\..") do set "C45_ROOT_RESOLVED=%%~fI"

set "C45_PROFILE_RESOLVED=default"
set "C45_ENV_RESOLVED=development"

set "C45_STATE_FILE=%C45_ROOT_RESOLVED%\.c45\state.json"
set "C45_ACTIVE_FILE=%C45_ROOT_RESOLVED%\.c45\active"
set "C45_BIN_RESOLVED=%C45_ROOT_RESOLVED%\.c45\bin"

if exist "%C45_STATE_FILE%" (
  for /f "usebackq tokens=2 delims=:," %%A in (`findstr /i /c:"\"profile\"" "%C45_STATE_FILE%"`) do (
    set "RAW=%%~A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    if not "!RAW!"=="" set "C45_PROFILE_RESOLVED=!RAW!"
  )
  for /f "usebackq tokens=2 delims=:," %%A in (`findstr /i /c:"\"environment\"" "%C45_STATE_FILE%"`) do (
    set "RAW=%%~A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    if not "!RAW!"=="" set "C45_ENV_RESOLVED=!RAW!"
  )
) else if exist "%C45_ACTIVE_FILE%" (
  set /p C45_ENV_RESOLVED=<"%C45_ACTIVE_FILE%"
)

set "C45_LABEL_RESOLVED=(%C45_PROFILE_RESOLVED%/%C45_ENV_RESOLVED%)"
set "C45_HAS_AOT=0"
if exist "%C45_BIN_RESOLVED%\c45.exe" set "C45_HAS_AOT=1"

REM End local scope and export into the calling CMD session.
endlocal & (
  set "C45_ROOT=%C45_ROOT_RESOLVED%"
  set "C45_PROFILE=%C45_PROFILE_RESOLVED%"
  set "C45_ENV_ID=%C45_ENV_RESOLVED%"
  set "C45_ACTIVE_LABEL=%C45_LABEL_RESOLVED%"
  if not defined _C45_OLD_PROMPT set "_C45_OLD_PROMPT=%PROMPT%"
  if not defined _C45_OLD_PATH set "_C45_OLD_PATH=%PATH%"
  set "PATH=%C45_BIN_RESOLVED%;%PATH%"
  set "PROMPT=%C45_LABEL_RESOLVED% $P$G"
  set "C45_HAS_AOT=%C45_HAS_AOT%"
  doskey deactivate="%C45_ROOT_RESOLVED%\scripts\env\deactivate.bat"
)

echo Activated Mosaic Retail: %C45_ACTIVE_LABEL%
echo   root: %C45_ROOT%
if "%C45_HAS_AOT%"=="1" (
  echo   cli:  c45.exe  ^(AOT on PATH^)
) else (
  echo   tip: melos run env:build  # compile AOT binary for faster c45
)
echo   tip: melos run env:use:staging then re-run activate.bat to refresh prompt
echo   tip: deactivate
set "C45_HAS_AOT="
