@echo off
REM Activate Vet45 env/profile for the current CMD session (like Python venv).
REM
REM Usage:
REM   scripts\env\activate.bat
REM   call scripts\env\activate.bat
REM
REM Deactivate:
REM   deactivate

setlocal EnableExtensions EnableDelayedExpansion

set "VET45_SCRIPT_DIR=%~dp0"
REM scripts\env\ -> repo root
for %%I in ("%VET45_SCRIPT_DIR%..\..") do set "VET45_ROOT_RESOLVED=%%~fI"

set "VET45_PROFILE_RESOLVED=default"
set "VET45_ENV_RESOLVED=development"

set "VET45_STATE_FILE=%VET45_ROOT_RESOLVED%\.vet45\state.json"
set "VET45_ACTIVE_FILE=%VET45_ROOT_RESOLVED%\.vet45\active"
set "VET45_BIN_RESOLVED=%VET45_ROOT_RESOLVED%\.vet45\bin"

if exist "%VET45_STATE_FILE%" (
  for /f "usebackq tokens=2 delims=:," %%A in (`findstr /i /c:"\"profile\"" "%VET45_STATE_FILE%"`) do (
    set "RAW=%%~A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    if not "!RAW!"=="" set "VET45_PROFILE_RESOLVED=!RAW!"
  )
  for /f "usebackq tokens=2 delims=:," %%A in (`findstr /i /c:"\"environment\"" "%VET45_STATE_FILE%"`) do (
    set "RAW=%%~A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    if not "!RAW!"=="" set "VET45_ENV_RESOLVED=!RAW!"
  )
) else if exist "%VET45_ACTIVE_FILE%" (
  set /p VET45_ENV_RESOLVED=<"%VET45_ACTIVE_FILE%"
)

set "VET45_LABEL_RESOLVED=(%VET45_PROFILE_RESOLVED%/%VET45_ENV_RESOLVED%)"
set "VET45_HAS_AOT=0"
if exist "%VET45_BIN_RESOLVED%\vet45.exe" set "VET45_HAS_AOT=1"

REM End local scope and export into the calling CMD session.
endlocal & (
  set "VET45_ROOT=%VET45_ROOT_RESOLVED%"
  set "VET45_PROFILE=%VET45_PROFILE_RESOLVED%"
  set "VET45_ENV_ID=%VET45_ENV_RESOLVED%"
  set "VET45_ACTIVE_LABEL=%VET45_LABEL_RESOLVED%"
  if not defined _VET45_OLD_PROMPT set "_VET45_OLD_PROMPT=%PROMPT%"
  if not defined _VET45_OLD_PATH set "_VET45_OLD_PATH=%PATH%"
  set "PATH=%VET45_BIN_RESOLVED%;%PATH%"
  set "PROMPT=%VET45_LABEL_RESOLVED% $P$G"
  set "VET45_HAS_AOT=%VET45_HAS_AOT%"
  doskey deactivate="%VET45_ROOT_RESOLVED%\scripts\env\deactivate.bat"
)

echo Activated Vet45: %VET45_ACTIVE_LABEL%
echo   root: %VET45_ROOT%
if "%VET45_HAS_AOT%"=="1" (
  echo   cli:  vet45.exe  ^(AOT on PATH^)
) else (
  echo   tip: melos run env:build  # compile AOT binary for faster vet45
)
echo   tip: melos run env:use:staging then re-run activate.bat to refresh prompt
echo   tip: deactivate
set "VET45_HAS_AOT="
