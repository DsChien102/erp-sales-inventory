# Backward-compatible alias → scripts/env/vet45.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "vet45.ps1") @args
exit $LASTEXITCODE
