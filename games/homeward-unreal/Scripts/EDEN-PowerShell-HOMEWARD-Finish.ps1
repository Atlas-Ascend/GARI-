# Ghost Atlas HOMEWARD EDEN PowerShell finish bootstrap
# Run in Windows PowerShell as Administrator on EDEN.
# Purpose: install/update tools, trust ARK1, wake EDEN services, pull HOMEWARD, wait for UE 5.8, package, verify, and emit receipts.

[CmdletBinding()]
param(
  [string]$UserName = 'Raymond',
  [string]$ArkPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGEzk1Jxty1889681OqIM8H6Zcn77jIL8JIXx3qTOO/z uO_a495@localhost',
  [string]$RepoUrl = 'https://github.com/Atlas-Ascend/GARI-.git',
  [string]$Branch = 'build/new-atlantis-homeward-unreal-5.8',
  [string]$RepoRoot = 'C:\Ghost\BUILD\GARI-HOMEWARD',
  [int]$WaitForUEHours = 6
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$RunRoot = "C:\Ghost\RUNS\EDEN-POWERSHELL-HOMEWARD-$Stamp"
$ReceiptPath = Join-Path $RunRoot 'EDEN-POWERSHELL-HOMEWARD-RECEIPT.json'
New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null

function Write-Receipt {
  param([string]$State, [hashtable]$Extra = @{})
  $base = [ordered]@{
    receipt_type = 'EDEN_POWERSHELL_HOMEWARD_FINISH_V1'
    state = $State
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    target_user = $UserName
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

function Install-WingetPackage {
  param([string]$Id, [string]$Name = $Id, [string]$Override = '')
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget missing; skipping $Name"
    return
  }
  Write-Host "Installing/updating $Name via winget..."
  $args = @('install','--id',$Id,'--exact','--silent','--accept-package-agreements','--accept-source-agreements')
  if ($Override) { $args += @('--override', $Override) }
  & winget @args
  if ($LASTEXITCODE -ne 0) {
    Write-Host "winget install returned $LASTEXITCODE for $Name; attempting upgrade/continuing."
    & winget upgrade --id $Id --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
  }
}

function Get-GitPath {
  $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $common = @('C:\Program Files\Git\cmd\git.exe', 'C:\Program Files\Git\bin\git.exe')
  foreach ($p in $common) { if (Test-Path $p) { return $p } }
  throw 'git.exe not found after install attempt.'
}

function Find-UERoot {
  $roots = New-Object System.Collections.Generic.List[string]
  if ($env:UE_ROOT) { $roots.Add($env:UE_ROOT) }
  @(
    'C:\Program Files\Epic Games\UE_5.8',
    'D:\Epic Games\UE_5.8',
    'C:\UnrealEngine-5.8',
    'C:\Ghost\UE\UnrealEngine-5.8',
    (Join-Path $RepoRoot 'games\homeward-unreal\.ue\UnrealEngine-5.8')
  ) | ForEach-Object { if ($_ -and -not $roots.Contains($_)) { $roots.Add($_) } }
  foreach ($root in $roots) {
    $uat = Join-Path $root 'Engine\Build\BatchFiles\RunUAT.bat'
    if (Test-Path $uat) { return $root }
  }
  return $null
}

try {
  if (-not (Test-Admin)) { throw 'Run this PowerShell as Administrator on EDEN.' }
  if ($env:OS -notmatch 'Windows') { throw 'This bootstrap must run on Windows EDEN.' }
  New-Item -ItemType Directory -Force -Path 'C:\Ghost' | Out-Null
  Write-Receipt -State 'EDEN_POWERSHELL_STARTED'

  Write-Host 'Installing base toolchain...'
  Install-WingetPackage -Id 'Git.Git' -Name 'Git'
  Install-WingetPackage -Id 'GitHub.cli' -Name 'GitHub CLI'
  Install-WingetPackage -Id 'Tailscale.Tailscale' -Name 'Tailscale'
  Install-WingetPackage -Id 'EpicGames.EpicGamesLauncher' -Name 'Epic Games Launcher'
  Install-WingetPackage -Id 'Microsoft.VisualStudio.2022.BuildTools' -Name 'Visual Studio 2022 Build Tools' -Override '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.NativeGame --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended'
  Write-Receipt -State 'TOOLCHAIN_REQUESTED'

  Write-Host 'Configuring OpenSSH server and ARK1 trust...'
  $cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Select-Object -First 1
  if ($cap -and $cap.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $cap.Name | Out-Null
  }
  Set-Service sshd -StartupType Automatic -ErrorAction SilentlyContinue
  Start-Service sshd -ErrorAction SilentlyContinue
  try {
    if (-not (Get-NetFirewallRule -DisplayName 'Ghost Atlas SSH Tailnet' -ErrorAction SilentlyContinue)) {
      New-NetFirewallRule -DisplayName 'Ghost Atlas SSH Tailnet' -Direction Inbound -Protocol TCP -LocalPort 22 -RemoteAddress '100.64.0.0/10' -Action Allow | Out-Null
    }
  } catch { Write-Host "Firewall rule skipped: $($_.Exception.Message)" }

  $UserProfile = "C:\Users\$UserName"
  $SshDir = Join-Path $UserProfile '.ssh'
  $Authorized = Join-Path $SshDir 'authorized_keys'
  New-Item -ItemType Directory -Force -Path $SshDir | Out-Null
  if (-not (Test-Path $Authorized)) { New-Item -ItemType File -Force -Path $Authorized | Out-Null }
  $Existing = Get-Content -Raw -ErrorAction SilentlyContinue $Authorized
  if ($Existing -notmatch [regex]::Escape($ArkPublicKey)) {
    Add-Content -Encoding ascii -Path $Authorized -Value $ArkPublicKey
  }
  icacls $SshDir /inheritance:r /grant "$UserName:(OI)(CI)F" /grant 'SYSTEM:(OI)(CI)F' | Out-Null
  icacls $Authorized /inheritance:r /grant "$UserName:F" /grant 'SYSTEM:F' | Out-Null
  Restart-Service sshd -ErrorAction SilentlyContinue
  Write-Receipt -State 'ARK1_KEY_TRUST_INSTALLED' -Extra @{ authorized_keys = $Authorized }

  Write-Host 'Waking Tailscale and GitHub Actions runner services...'
  $tailscaleSvc = Get-Service -Name Tailscale -ErrorAction SilentlyContinue
  if ($tailscaleSvc) {
    Set-Service Tailscale -StartupType Automatic -ErrorAction SilentlyContinue
    if ($tailscaleSvc.Status -ne 'Running') { Start-Service Tailscale -ErrorAction SilentlyContinue }
  }
  $runnerServices = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'actions.runner*' -or $_.DisplayName -like '*GitHub Actions Runner*' })
  foreach ($svc in $runnerServices) {
    try {
      Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
      if ($svc.Status -ne 'Running') { Start-Service -Name $svc.Name -ErrorAction SilentlyContinue }
    } catch { Write-Host "Runner service wake skipped for $($svc.Name): $($_.Exception.Message)" }
  }
  Write-Receipt -State 'EDEN_SERVICES_WOKEN' -Extra @{ runner_services = @($runnerServices | ForEach-Object { $_.Name }) }

  $git = Get-GitPath
  Write-Host "Using git: $git"
  if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $RepoRoot -Parent) | Out-Null
    & $git clone --branch $Branch --depth 1 $RepoUrl $RepoRoot
  } else {
    & $git -C $RepoRoot fetch origin $Branch --depth 1
    & $git -C $RepoRoot checkout $Branch
    & $git -C $RepoRoot reset --hard "origin/$Branch"
  }
  if ($LASTEXITCODE -ne 0) { throw 'Git HOMEWARD checkout failed.' }
  $Head = (& $git -C $RepoRoot rev-parse HEAD).Trim()
  Write-Receipt -State 'HOMEWARD_SOURCE_READY' -Extra @{ repo_root = $RepoRoot; head_sha = $Head }

  $ProjectRoot = Join-Path $RepoRoot 'games\homeward-unreal'
  $PackageScript = Join-Path $ProjectRoot 'Scripts\Package-And-PixelStream.ps1'
  $VerifyScript = Join-Path $ProjectRoot 'Scripts\Verify-HomewardPackageProof.ps1'
  if (-not (Test-Path $PackageScript)) { throw "Missing package script: $PackageScript" }
  if (-not (Test-Path $VerifyScript)) { throw "Missing verifier script: $VerifyScript" }

  $EpicLauncher = @(
    'C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe',
    'C:\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($EpicLauncher) {
    Write-Host 'Launching Epic Games Launcher. Log in with the new Epic account and install Unreal Engine 5.8 when prompted.'
    Start-Process -FilePath $EpicLauncher -ErrorAction SilentlyContinue
  }

  $deadline = (Get-Date).AddHours($WaitForUEHours)
  $UERoot = Find-UERoot
  while (-not $UERoot -and (Get-Date) -lt $deadline) {
    Write-Host 'WAITING_FOR_UNREAL_ENGINE_5_8. Install UE 5.8 in Epic Launcher; this script will continue automatically.'
    Write-Receipt -State 'WAITING_FOR_UNREAL_ENGINE_5_8' -Extra @{ epic_launcher = $EpicLauncher; deadline_utc = $deadline.ToUniversalTime().ToString('o') }
    Start-Sleep -Seconds 30
    $UERoot = Find-UERoot
  }
  if (-not $UERoot) { throw 'UE 5.8 was not found before wait deadline. Install UE_5.8, then rerun this same PowerShell command.' }
  [Environment]::SetEnvironmentVariable('UE_ROOT', $UERoot, 'User')
  $env:UE_ROOT = $UERoot
  Write-Receipt -State 'UNREAL_ENGINE_5_8_READY' -Extra @{ ue_root = $UERoot; head_sha = $Head }

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
  Write-Receipt -State 'EDEN_POWERSHELL_HOMEWARD_REPAIR_REQUIRED' -Extra @{ error = $_.Exception.Message }
  Write-Error $_
  exit 1
}
