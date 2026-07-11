# Thin PowerShell shim — prefer AOT binary, else dart run.
#
# Usage:
#   .\scripts\env\vet45.ps1 list
#   pwsh scripts/env/vet45.ps1 sync --target erp

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$bin = Join-Path $repoRoot ".vet45\bin\vet45.exe"

if (Test-Path $bin) {
  & $bin @args
  exit $LASTEXITCODE
}

Write-Host "tip: run ``melos run env:build`` once for a faster AOT binary (falling back to dart run)" -ForegroundColor DarkYellow
Push-Location $repoRoot
try {
  dart run tools/vet45_env/bin/vet45_env.dart @args
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
