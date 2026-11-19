# Backward-compatible alias → scripts/env/c45.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "c45.ps1") @args
exit $LASTEXITCODE
