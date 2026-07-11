# Activate Vet45 env/profile for the current PowerShell session (like Python venv).
#
# Usage:
#   . .\scripts\env\activate.ps1
#   . scripts/env/activate.ps1
#
# Deactivate:
#   deactivate

function global:_Vet45ReadState {
  param([string]$RepoRoot)

  $profileId = "default"
  $environmentId = "development"
  $stateFile = Join-Path $RepoRoot ".vet45\state.json"
  $activeFile = Join-Path $RepoRoot ".vet45\active"

  if (Test-Path $stateFile) {
    try {
      $json = Get-Content -Raw -Path $stateFile | ConvertFrom-Json
      if ($json.profile) { $profileId = [string]$json.profile }
      if ($json.environment) { $environmentId = [string]$json.environment }
    } catch {
      # keep defaults
    }
  } elseif (Test-Path $activeFile) {
    $raw = (Get-Content -Raw -Path $activeFile).Trim()
    if ($raw) { $environmentId = $raw }
  }

  return @{
    Profile = $profileId
    Environment = $environmentId
    Label = "($profileId/$environmentId)"
  }
}

function global:_Vet45RefreshExports {
  $state = _Vet45ReadState -RepoRoot $env:VET45_ROOT
  $env:VET45_PROFILE = $state.Profile
  $env:VET45_ENV_ID = $state.Environment
  $env:VET45_ACTIVE_LABEL = $state.Label
}

function global:deactivate {
  if (Test-Path Function:_Vet45OldPrompt) {
    Copy-Item -Path Function:_Vet45OldPrompt -Destination Function:prompt -Force
    Remove-Item -Path Function:_Vet45OldPrompt -Force -ErrorAction SilentlyContinue
  } elseif (Test-Path Function:prompt) {
    Remove-Item -Path Function:prompt -Force -ErrorAction SilentlyContinue
  }

  if ($env:_VET45_OLD_PATH) {
    $env:PATH = $env:_VET45_OLD_PATH
    Remove-Item Env:_VET45_OLD_PATH -ErrorAction SilentlyContinue
  }

  Remove-Item Env:VET45_ROOT -ErrorAction SilentlyContinue
  Remove-Item Env:VET45_PROFILE -ErrorAction SilentlyContinue
  Remove-Item Env:VET45_ENV_ID -ErrorAction SilentlyContinue
  Remove-Item Env:VET45_ACTIVE_LABEL -ErrorAction SilentlyContinue

  Remove-Item Function:_Vet45ReadState -ErrorAction SilentlyContinue
  Remove-Item Function:_Vet45RefreshExports -ErrorAction SilentlyContinue
  Remove-Item Function:deactivate -ErrorAction SilentlyContinue
}

# Resolve repo root from this script location: scripts/env -> repo
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path

# Re-activate cleanly
if (Get-Command deactivate -ErrorAction SilentlyContinue) {
  deactivate | Out-Null
}

$env:VET45_ROOT = $repoRoot
_Vet45RefreshExports

$binDir = Join-Path $repoRoot ".vet45\bin"
$env:_VET45_OLD_PATH = $env:PATH
if (-not (($env:PATH -split ';') -contains $binDir)) {
  $env:PATH = "$binDir;$($env:PATH)"
}

# Preserve previous prompt, then wrap with (profile/env)
if (Test-Path Function:prompt) {
  Copy-Item -Path Function:prompt -Destination Function:_Vet45OldPrompt -Force
} else {
  function global:_Vet45OldPrompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
}

function global:prompt {
  _Vet45RefreshExports | Out-Null
  $label = $env:VET45_ACTIVE_LABEL
  if (-not $label) { $label = "(vet45)" }
  "$label $(&_Vet45OldPrompt)"
}

Write-Host "Activated Vet45: $($env:VET45_ACTIVE_LABEL)"
Write-Host "  root: $($env:VET45_ROOT)"
$exe = Join-Path $binDir "vet45.exe"
if (Test-Path $exe) {
  Write-Host "  cli:  vet45.exe  (AOT on PATH)"
} else {
  Write-Host "  tip: melos run env:build  # compile AOT binary for faster vet45"
}
Write-Host "  tip: melos run env:use:staging  # prompt updates automatically"
Write-Host "  tip: deactivate"
