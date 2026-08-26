# Ghost Atlas HOMEWARD EDEN no-loop finisher
# Run in Administrator PowerShell on EDEN.
# Purpose: stop launcher reinstall loops, detect UE exactly once, build when ready, otherwise exit cleanly with proof.

[CmdletBinding()]
param(
  [string]$RepoUrl = 'https://github.com/Atlas-Ascend/GARI-.git',
  [string]$Branch = 'build/new-atlantis-homeward-unreal-5.8',
  [string]$RepoRoot = 'C:\Ghost\BUILD\GARI-HOMEWARD',
  [string]$RequiredUE = 'UE_5.8',
  [switch]$AcceptAnyUE5
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$RunRoot = "C:\Ghost\RUNS\EDEN-HOMEWARD-NOLOOP-$Stamp"
$ReceiptPath = Join-Path $RunRoot 'EDEN-HOMEWARD-NOLOOP-RECEIPT.json'
New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null

function Write-Receipt {
  param([string]$State, [hashtable]$Extra = @{})
  $base = [ordered]@{
    receipt_type = 'EDEN_HOMEWARD_NOLOOP_V1'
    state = $State
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    user_profile = $env:USERPROFILE
    ghost_root = 'C:\Ghost'
    run_root = $RunRoot
  }
  foreach ($k in $Extra.Keys) { $base[$k] = $Extra[$k] }
  $base | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $ReceiptPath
  Write-Host "RECEIPT_STATE=$State"
}

function Test-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-GitPath {
  $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($p in @('C:\Program Files\Git\cmd\git.exe','C:\Program Files\Git\bin\git.exe')) {
    if (Test-Path $p) { return $p }
  }
  throw 'git.exe missing. Install Git or rerun the full bootstrap once.'
}

function Find-EpicLauncher {
  @(
    'C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe',
    'C:\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Find-UERoots {
  $roots = New-Object System.Collections.Generic.List[string]
  if ($env:UE_ROOT) { $roots.Add($env:UE_ROOT) }
  $baseDirs = @(
    'C:\Program Files\Epic Games',
    'D:\Epic Games',
    'E:\Epic Games',
    'C:\UnrealEngine-5.8',
    'C:\Ghost\UE',
    (Join-Path $RepoRoot 'games\homeward-unreal\.ue')
  )
  foreach ($base in $baseDirs) {
    if (Test-Path $base) {
      if ((Split-Path $base -Leaf) -like 'UE_*') { $roots.Add($base) }
      Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'UE_*' } | ForEach-Object { $roots.Add($_.FullName) }
    }
  }
  $valid = @()
  foreach ($root in ($roots | Select-Object -Unique)) {
    $uat = Join-Path $root 'Engine\Build\BatchFiles\RunUAT.bat'
    if (Test-Path $uat) { $valid += $root }
  }
  return $valid
}

function Select-UERoot {
  $roots = @(Find-UERoots)
  $exact = $roots | Where-Object { (Split-Path $_ -Leaf) -eq $RequiredUE } | Select-Object -First 1
  if ($exact) { return $exact }
  if ($AcceptAnyUE5 -and $roots.Count -gt 0) {
    return ($roots | Sort-Object -Descending | Select-Object -First 1)
  }
  return $null
}

try {
  if (-not (Test-Admin)) { throw 'Run this from Administrator PowerShell.' }
  New-Item -ItemType Directory -Force -Path 'C:\Ghost' | Out-Null
  Write-Receipt -State 'NOLOOP_STARTED'

  # Stop launcher thrash, but do not uninstall or reinstall anything.
  Get-Process -Name 'EpicGamesLauncher','EpicWebHelper','EpicOnlineServices' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 3

  # Repair ARK1 trust against the real current Windows profile, not a guessed user name.
  $ArkPublicKeyPath = 'C:\Ghost\RUNS\ARK1-PUBLIC-KEY.txt'
  $SshDir = Join-Path $env:USERPROFILE '.ssh'
  $Authorized = Join-Path $SshDir 'authorized_keys'
  New-Item -ItemType Directory -Force -Path $SshDir | Out-Null
  if (-not (Test-Path $Authorized)) { New-Item -ItemType File -Force -Path $Authorized | Out-Null }
  $KnownKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGEzk1Jxty1889681OqIM8H6Zcn77jIL8JIXx3qTOO/z uO_a495@localhost'
  $Existing = Get-Content -Raw -ErrorAction SilentlyContinue $Authorized
  if ($Existing -notmatch [regex]::Escape($KnownKey)) { Add-Content -Encoding ascii -Path $Authorized -Value $KnownKey }
  $Acct = "$($env:USERDOMAIN)\$($env:USERNAME)"
  icacls $SshDir /inheritance:r /grant "${Acct}:(OI)(CI)F" /grant 'SYSTEM:(OI)(CI)F' | Out-Null
  icacls $Authorized /inheritance:r /grant "${Acct}:F" /grant 'SYSTEM:F' | Out-Null
  Restart-Service sshd -ErrorAction SilentlyContinue
  Write-Receipt -State 'LOCAL_USER_SSH_TRUST_REPAIRED' -Extra @{ windows_account = $Acct; authorized_keys = $Authorized }

  $git = Find-GitPath
  if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $RepoRoot -Parent) | Out-Null
    & $git clone --branch $Branch --depth 1 $RepoUrl $RepoRoot
  } else {
    & $git -C $RepoRoot fetch origin $Branch --depth 1
    & $git -C $RepoRoot checkout $Branch
    & $git -C $RepoRoot reset --hard "origin/$Branch"
  }
  if ($LASTEXITCODE -ne 0) { throw 'HOMEWARD source checkout failed.' }
  $Head = (& $git -C $RepoRoot rev-parse HEAD).Trim()
  Write-Receipt -State 'HOMEWARD_SOURCE_READY' -Extra @{ repo_root = $RepoRoot; head_sha = $Head }

  $UERoot = Select-UERoot
  if (-not $UERoot) {
    $EpicLauncher = Find-EpicLauncher
    if ($EpicLauncher) { Start-Process -FilePath $EpicLauncher -ErrorAction SilentlyContinue }
    $SeenRoots = @(Find-UERoots)
    Write-Host "UE_5.8 not detected. No loop. Install Unreal Engine 5.8, then rerun this same no-loop command."
    Write-Host "Required detector: C:\Program Files\Epic Games\UE_5.8\Engine\Build\BatchFiles\RunUAT.bat"
    Write-Receipt -State 'UE_5_8_NOT_FOUND_NOLOOP_EXIT' -Extra @{ seen_ue_roots = $SeenRoots; epic_launcher = $EpicLauncher; required = $RequiredUE; accept_any_ue5 = [bool]$AcceptAnyUE5 }
    exit 58
  }

  [Environment]::SetEnvironmentVariable('UE_ROOT', $UERoot, 'User')
  $env:UE_ROOT = $UERoot
  Write-Receipt -State 'UNREAL_ENGINE_READY' -Extra @{ ue_root = $UERoot; required = $RequiredUE; accept_any_ue5 = [bool]$AcceptAnyUE5 }

  $ProjectRoot = Join-Path $RepoRoot 'games\homeward-unreal'
  $PackageScript = Join-Path $ProjectRoot 'Scripts\Package-And-PixelStream.ps1'
  $VerifyScript = Join-Path $ProjectRoot 'Scripts\Verify-HomewardPackageProof.ps1'
  if (-not (Test-Path $PackageScript)) { throw "Missing package script: $PackageScript" }
  if (-not (Test-Path $VerifyScript)) { throw "Missing verifier script: $VerifyScript" }

  $ArchiveDir = "C:\Ghost\RELEASES\GhostAtlas-HOMEWARD-Unreal-5.8-$Stamp"
  New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null
  Write-Receipt -State 'HOMEWARD_PACKAGE_STARTED' -Extra @{ archive_dir = $ArchiveDir; ue_root = $UERoot; head_sha = $Head }

  Push-Location $ProjectRoot
  try {
    & $PackageScript -UE_ROOT $UERoot -ArchiveDir $ArchiveDir
    if ($LASTEXITCODE -ne 0) { throw 'Package-And-PixelStream returned nonzero.' }
    & $VerifyScript -ArchiveDir $ArchiveDir
    if ($LASTEXITCODE -ne 0) { throw 'Verify-HomewardPackageProof returned nonzero.' }
  } finally {
    Pop-Location
  }

  $ProofObjects = @(
    (Join-Path $ArchiveDir 'HOMEWARD-WHOLE-PACKAGE-DIGEST.json'),
    (Join-Path $ArchiveDir 'HOMEWARD-PIXELSTREAM-RECEIPT.json'),
    (Join-Path $ArchiveDir 'HOMEWARD-PACKAGE-PROOF-VERIFICATION.json')
  )
  foreach ($p in $ProofObjects) { if (-not (Test-Path $p)) { throw "Missing final proof object: $p" } }

  Get-ChildItem $ArchiveDir -Recurse -File | Get-FileHash -Algorithm SHA256 | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $RunRoot 'FINAL-RELEASE-HASHES.json')
  Write-Receipt -State 'GHOST_ATLAS_HOMEWARD_RUNTIME_READY_FOR_ARK_QA' -Extra @{
    head_sha = $Head
    ue_root = $UERoot
    archive_dir = $ArchiveDir
    digest = $ProofObjects[0]
    pixelstream_receipt = $ProofObjects[1]
    verifier_receipt = $ProofObjects[2]
  }
  Write-Host 'GHOST_ATLAS_HOMEWARD_RUNTIME_READY_FOR_ARK_QA'
  Write-Host "Receipt: $ReceiptPath"
  Write-Host "Archive: $ArchiveDir"
}
catch {
  Write-Receipt -State 'EDEN_HOMEWARD_NOLOOP_REPAIR_REQUIRED' -Extra @{ error = $_.Exception.Message }
  Write-Error $_
  exit 1
}
