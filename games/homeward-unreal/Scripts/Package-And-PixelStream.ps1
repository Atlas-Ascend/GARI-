param(
    [string]$UE_ROOT = $env:UE_ROOT,
    [string]$ArchiveDir = "$PSScriptRoot\..\Build\PixelStreaming",
    [int]$HttpPort = 80,
    [int]$StreamerPort = 8888
)

$ErrorActionPreference = "Stop"
$ProjectRoot = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")
$Project = Join-Path $ProjectRoot "Homeward.uproject"
$ArchiveDir = [System.IO.Path]::GetFullPath($ArchiveDir)
$ProofDir = Join-Path $ArchiveDir "HOMEWARD-PROOF"

function Write-JsonFile {
    param(
        [Parameter(Mandatory=$true)]$Object,
        [Parameter(Mandatory=$true)][string]$Path
    )
    $Object | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 $Path
}

function Get-DeterministicPackageDigest {
    param([Parameter(Mandatory=$true)][string]$Root)

    $interestingExtensions = @('.exe', '.pak', '.ucas', '.utoc', '.umap', '.uasset', '.ini', '.dll')
    $files = Get-ChildItem -Path $Root -Recurse -File |
        Where-Object {
            $relative = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
            ($interestingExtensions -contains $_.Extension.ToLowerInvariant()) -or
            ($relative -match '(?i)(Windows|WindowsNoEditor|Content|Config|Engine|Homeward)')
        } |
        Sort-Object { $_.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\','/').ToLowerInvariant() }

    if (-not $files -or $files.Count -eq 0) {
        throw "No package files found for digest under $Root"
    }

    $records = @()
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\','/')
        $hash = Get-FileHash -Algorithm SHA256 -Path $file.FullName
        $records += [ordered]@{
            path = $relative
            size_bytes = $file.Length
            sha256 = $hash.Hash.ToLowerInvariant()
        }
    }

    $canonical = ($records | ForEach-Object { "$($_.sha256)  $($_.size_bytes)  $($_.path)" }) -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $digest = [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()

    return [ordered]@{
        algorithm = 'SHA256_OF_SORTED_FILE_HASH_RECORDS_V1'
        digest = $digest
        file_count = $records.Count
        records = $records
    }
}

if (-not $UE_ROOT) {
    $LocalEngine = Join-Path $ProjectRoot ".ue\UnrealEngine-5.8"
    if (Test-Path $LocalEngine) { $UE_ROOT = $LocalEngine }
}
if (-not $UE_ROOT) { throw "UE_ROOT is not set and no local .ue/UnrealEngine-5.8 install exists." }

$UAT = Join-Path $UE_ROOT "Engine\Build\BatchFiles\RunUAT.bat"
if (-not (Test-Path $UAT)) { throw "RunUAT not found at $UAT" }

New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

& $UAT BuildCookRun `
    -project="$Project" `
    -noP4 `
    -platform=Win64 `
    -clientconfig=Shipping `
    -build -cook -allmaps -stage -pak -archive `
    -archivedirectory="$ArchiveDir"
if ($LASTEXITCODE -ne 0) { throw "Unreal package failed." }

$Exe = Get-ChildItem -Path $ArchiveDir -Filter "Homeward.exe" -Recurse | Select-Object -First 1
if (-not $Exe) { throw "Packaged Homeward.exe not found under $ArchiveDir" }

$PackageDigest = Get-DeterministicPackageDigest -Root $ArchiveDir
Write-JsonFile -Object $PackageDigest -Path (Join-Path $ProofDir "HOMEWARD-WHOLE-PACKAGE-DIGEST.json")

$Infra = Join-Path $ProjectRoot ".pixelstreaming\PixelStreamingInfrastructure"
if (-not (Test-Path "$Infra\.git")) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Infra -Parent) | Out-Null
    & git clone --depth 1 --branch UE5.8 https://github.com/EpicGames/PixelStreamingInfrastructure.git $Infra
    if ($LASTEXITCODE -ne 0) { throw "Pixel Streaming Infrastructure clone failed." }
}

$Signal = Join-Path $Infra "SignallingWebServer\platform_scripts\cmd\start.bat"
if (-not (Test-Path $Signal)) { throw "Pixel Streaming signalling server script not found: $Signal" }

Write-Host "Starting Pixel Streaming signalling/web server..."
$SignalProcess = Start-Process -FilePath $Signal -WorkingDirectory (Split-Path $Signal -Parent) -PassThru
Start-Sleep -Seconds 5

$Args = @(
    "-RenderOffScreen",
    "-AudioMixer",
    "-PixelStreamingURL=ws://127.0.0.1:$StreamerPort",
    "-ResX=1920",
    "-ResY=1080",
    "-Windowed"
)

Write-Host "Starting Unreal game: $($Exe.FullName)"
$Game = Start-Process -FilePath $Exe.FullName -ArgumentList $Args -PassThru
Start-Sleep -Seconds 8
if ($Game.HasExited) { throw "Homeward exited during launch smoke test with code $($Game.ExitCode)." }

$ExecutableHash = Get-FileHash -Algorithm SHA256 -Path $Exe.FullName
$Receipt = [ordered]@{
    receipt_type = 'HOMEWARD_UNREAL_PACKAGE_PIXELSTREAM_V1'
    state = 'HOMEWARD_UNREAL_RUNNING'
    project = 'Ghost Atlas: New Atlantis HOMEWARD'
    engine = 'Unreal Engine 5.8'
    repository = $env:GITHUB_REPOSITORY
    commit_sha = $env:GITHUB_SHA
    run_id = $env:GITHUB_RUN_ID
    run_attempt = $env:GITHUB_RUN_ATTEMPT
    runner_name = $env:RUNNER_NAME
    runner_os = $env:RUNNER_OS
    machine = $env:COMPUTERNAME
    archive_dir = $ArchiveDir
    executable = $Exe.FullName
    executable_sha256 = $ExecutableHash.Hash.ToLowerInvariant()
    whole_package_digest = $PackageDigest.digest
    whole_package_digest_algorithm = $PackageDigest.algorithm
    whole_package_file_count = $PackageDigest.file_count
    pixel_streaming = [ordered]@{
        http_port = $HttpPort
        streamer_port = $StreamerPort
        browser_player = "http://127.0.0.1:$HttpPort"
        streamer_websocket = "ws://127.0.0.1:$StreamerPort"
        game_pid = $Game.Id
        signalling_pid = $SignalProcess.Id
    }
    proof = [ordered]@{
        package_digest_file = 'HOMEWARD-PROOF/HOMEWARD-WHOLE-PACKAGE-DIGEST.json'
        receipt_file = 'HOMEWARD-PROOF/HOMEWARD-PIXELSTREAM-RECEIPT.json'
    }
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
}

Write-JsonFile -Object $Receipt -Path (Join-Path $ProofDir "HOMEWARD-PIXELSTREAM-RECEIPT.json")
Get-FileHash (Join-Path $ProofDir "HOMEWARD-PIXELSTREAM-RECEIPT.json") -Algorithm SHA256 |
    ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $ProofDir "HOMEWARD-PIXELSTREAM-RECEIPT.sha256.json")

Write-Host "HOMEWARD_UNREAL_RUNNING"
Write-Host "HOMEWARD_WHOLE_PACKAGE_DIGEST=$($PackageDigest.digest)"
Write-Host "HOMEWARD_RECEIPT=$(Join-Path $ProofDir 'HOMEWARD-PIXELSTREAM-RECEIPT.json')"
Write-Host "Browser player: http://127.0.0.1:$HttpPort"
Write-Host "Streamer websocket: ws://127.0.0.1:$StreamerPort"
Write-Host "PID: $($Game.Id)"
