#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

printf '\n🜂 Ghost Atlas HOMEWARD Hypernet Finish Launcher\n'
printf 'Termux → Tailscale → EDEN → Unreal 5.8 → Pixel Streaming proof\n\n'

pkg_ready() {
  command -v pkg >/dev/null 2>&1
}

when_pkg_install() {
  if pkg_ready; then
    pkg update -y >/dev/null || true
    pkg install -y openssh git curl jq coreutils >/dev/null || true
  fi
}

when_pkg_install

EDEN_USER="${EDEN_USER:-Raymond}"
EDEN_HOST="${EDEN_HOST:-eden}"
EDEN_PORT="${EDEN_PORT:-22}"
TARGET="${EDEN_USER}@${EDEN_HOST}"
SSH_OPTS=(-p "$EDEN_PORT" -o ConnectTimeout=8 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=accept-new)

printf 'EDEN target: %s:%s\n' "$TARGET" "$EDEN_PORT"
printf 'Checking Tailnet/SSH reachability...\n'

if command -v tailscale >/dev/null 2>&1; then
  tailscale status >/dev/null 2>&1 || true
fi

REMOTE_TEST='powershell -NoProfile -ExecutionPolicy Bypass -Command "if ((Test-Path C:\Ghost) -and ($env:OS -match '\''Windows'\'')) { Write-Output '\''EDEN_READY'\'' } else { throw '\''Not physical EDEN: C:\Ghost missing or OS invalid.'\'' }"'

ssh "${SSH_OPTS[@]}" "$TARGET" "$REMOTE_TEST"

WORKDIR="${TMPDIR:-/tmp}/ghost-atlas-homeward-finish"
mkdir -p "$WORKDIR"
PS1="$WORKDIR/GA-HOMEWARD-FINISH.ps1"

cat > "$PS1" <<'POWERSHELL'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$RunRoot = "C:\Ghost\RUNS\HOMEWARD-HYPERNET-$Stamp"
New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
$ReceiptPath = Join-Path $RunRoot 'EDEN-HYPERNET-HOMEWARD-FINISH-RECEIPT.json'

function Write-Receipt {
  param([string]$State, [hashtable]$Extra = @{})
  $base = [ordered]@{
    receipt_type = 'EDEN_HYPERNET_HOMEWARD_FINISH_V1'
    state = $State
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    ghost_root = 'C:\Ghost'
    run_root = $RunRoot
  }
  foreach ($k in $Extra.Keys) { $base[$k] = $Extra[$k] }
  $base | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 $ReceiptPath
}

try {
  if (-not (Test-Path 'C:\Ghost')) { throw 'C:\Ghost missing; this SSH target is not accepted as EDEN.' }
  Write-Receipt -State 'EDEN_ACCEPTED'

  $runnerServices = @(Get-Service -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like 'actions.runner*' -or $_.DisplayName -like '*GitHub Actions Runner*'
  })
  foreach ($svc in $runnerServices) {
    if ($svc.Status -ne 'Running') {
      try { Start-Service -Name $svc.Name -ErrorAction Stop } catch { }
    }
  }
  Start-Sleep -Seconds 3

  $RepoRoot = 'C:\Ghost\BUILD\GARI-HOMEWARD'
  if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $RepoRoot -Parent) | Out-Null
    git clone --branch build/new-atlantis-homeward-unreal-5.8 --depth 1 https://github.com/Atlas-Ascend/GARI-.git $RepoRoot
  } else {
    git -C $RepoRoot fetch origin build/new-atlantis-homeward-unreal-5.8 --depth 1
    git -C $RepoRoot checkout build/new-atlantis-homeward-unreal-5.8
    git -C $RepoRoot reset --hard origin/build/new-atlantis-homeward-unreal-5.8
  }
  if ($LASTEXITCODE -ne 0) { throw 'Git checkout failed.' }

  $Head = (git -C $RepoRoot rev-parse HEAD).Trim()
  Write-Receipt -State 'SOURCE_READY' -Extra @{ repo_root = $RepoRoot; head_sha = $Head; runner_services = @($runnerServices | ForEach-Object { $_.Name }) }

  $ProjectRoot = Join-Path $RepoRoot 'games\homeward-unreal'
  $PackageScript = Join-Path $ProjectRoot 'Scripts\Package-And-PixelStream.ps1'
  $VerifyScript = Join-Path $ProjectRoot 'Scripts\Verify-HomewardPackageProof.ps1'
  if (-not (Test-Path $PackageScript)) { throw "Missing package script: $PackageScript" }
  if (-not (Test-Path $VerifyScript)) { throw "Missing verifier script: $VerifyScript" }

  $candidateUERoots = @()
  if ($env:UE_ROOT) { $candidateUERoots += $env:UE_ROOT }
  $candidateUERoots += @(
    'C:\Program Files\Epic Games\UE_5.8',
    'C:\UnrealEngine-5.8',
    'C:\Ghost\UE\UnrealEngine-5.8',
    (Join-Path $ProjectRoot '.ue\UnrealEngine-5.8')
  )
  $UERoot = $candidateUERoots | Where-Object { $_ -and (Test-Path (Join-Path $_ 'Engine\Build\BatchFiles\RunUAT.bat')) } | Select-Object -First 1

  if (-not $UERoot) {
    $SetupScript = Join-Path $ProjectRoot 'Scripts\Setup-Unreal58.ps1'
    if (Test-Path $SetupScript) {
      Write-Receipt -State 'UE58_SETUP_ATTEMPT' -Extra @{ head_sha = $Head; setup_script = $SetupScript }
      & $SetupScript
      if ($LASTEXITCODE -ne 0) { throw 'UE 5.8 setup script returned nonzero.' }
      $UERoot = $candidateUERoots | Where-Object { $_ -and (Test-Path (Join-Path $_ 'Engine\Build\BatchFiles\RunUAT.bat')) } | Select-Object -First 1
    }
  }

  if (-not $UERoot) { throw 'UE_ROOT unresolved. EDEN needs Unreal Engine 5.8 installed or UE_ROOT set.' }

  $ArchiveDir = "C:\Ghost\RELEASES\GhostAtlas-HOMEWARD-Unreal-5.8-$Stamp"
  Write-Receipt -State 'UE58_PACKAGE_STARTED' -Extra @{ head_sha = $Head; ue_root = $UERoot; archive_dir = $ArchiveDir }

  Push-Location $ProjectRoot
  try {
    & $PackageScript -UE_ROOT $UERoot -ArchiveDir $ArchiveDir
    if ($LASTEXITCODE -ne 0) { throw 'Package-And-PixelStream returned nonzero.' }
    & $VerifyScript -ArchiveDir $ArchiveDir
    if ($LASTEXITCODE -ne 0) { throw 'Verify-HomewardPackageProof returned nonzero.' }
  } finally {
    Pop-Location
  }

  $Digest = Join-Path $ArchiveDir 'HOMEWARD-WHOLE-PACKAGE-DIGEST.json'
  $Pixel = Join-Path $ArchiveDir 'HOMEWARD-PIXELSTREAM-RECEIPT.json'
  $Verify = Join-Path $ArchiveDir 'HOMEWARD-PACKAGE-PROOF-VERIFICATION.json'
  foreach ($required in @($Digest,$Pixel,$Verify)) {
    if (-not (Test-Path $required)) { throw "Missing final proof object: $required" }
  }

  $finalHashes = Get-ChildItem $ArchiveDir -Recurse -File | Get-FileHash -Algorithm SHA256
  $finalHashes | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $RunRoot 'FINAL-RELEASE-HASHES.json')

  Write-Receipt -State 'GHOST_ATLAS_HOMEWARD_RUNTIME_READY_FOR_ARK_QA' -Extra @{
    head_sha = $Head
    ue_root = $UERoot
    archive_dir = $ArchiveDir
    digest = $Digest
    pixelstream_receipt = $Pixel
    verifier_receipt = $Verify
  }

  Write-Host 'GHOST_ATLAS_HOMEWARD_RUNTIME_READY_FOR_ARK_QA'
  Write-Host "Receipt: $ReceiptPath"
  Write-Host "Archive: $ArchiveDir"
}
catch {
  Write-Receipt -State 'EDEN_HYPERNET_HOMEWARD_REPAIR_REQUIRED' -Extra @{ error = $_.Exception.Message }
  Write-Error $_
  exit 1
}
POWERSHELL

printf 'Copying bounded EDEN finish script...\n'
scp "${SSH_OPTS[@]}" "$PS1" "$TARGET:GA-HOMEWARD-FINISH.ps1"

printf 'Executing on EDEN through the Hypernet...\n'
ssh "${SSH_OPTS[@]}" "$TARGET" 'powershell -NoProfile -ExecutionPolicy Bypass -File GA-HOMEWARD-FINISH.ps1'

printf '\n🜁 HOMEWARD Hypernet finish command completed.\n'
