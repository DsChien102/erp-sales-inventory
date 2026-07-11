@echo off
REM Deactivate Vet45 CMD session activated via scripts\env\activate.bat

if defined _VET45_OLD_PROMPT (
  set "PROMPT=%_VET45_OLD_PROMPT%"
  set "_VET45_OLD_PROMPT="
)

set "VET45_ROOT="
set "VET45_PROFILE="
set "VET45_ENV_ID="
set "VET45_ACTIVE_LABEL="

doskey deactivate=

echo Deactivated Vet45 environment.
