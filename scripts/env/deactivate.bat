@echo off
REM Deactivate Mosaic Retail CMD session activated via scripts\env\activate.bat

if defined _C45_OLD_PROMPT (
  set "PROMPT=%_C45_OLD_PROMPT%"
  set "_C45_OLD_PROMPT="
)

if defined _C45_OLD_PATH (
  set "PATH=%_C45_OLD_PATH%"
  set "_C45_OLD_PATH="
)

set "C45_ROOT="
set "C45_PROFILE="
set "C45_ENV_ID="
set "C45_ACTIVE_LABEL="

doskey deactivate=

echo Deactivated Mosaic Retail environment.
