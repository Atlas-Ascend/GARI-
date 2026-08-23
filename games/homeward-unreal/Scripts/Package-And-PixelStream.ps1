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

if (-not $UE_ROOT) {
    $LocalEngine = Join-Path $ProjectRoot ".ue\UnrealEngine-5.8"
    if (Test-Path $LocalEngine) { $UE_ROOT = $LocalEngine }
}
if (-not $UE_ROOT) { throw "UE_ROOT is not set and no local .ue/UnrealEngine-5.8 install exists." }

$UAT = Join-Path $UE_ROOT "Engine\Build\BatchFiles\RunUAT.bat"
if (-not (Test-Path $UAT)) { throw "RunUAT not found at $UAT" }

New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

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

$Infra = Join-Path $ProjectRoot ".pixelstreaming\PixelStreamingInfrastructure"
if (-not (Test-Path "$Infra\.git")) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Infra -Parent) | Out-Null
    & git clone --depth 1 --branch UE5.8 https://github.com/EpicGames/PixelStreamingInfrastructure.git $Infra
    if ($LASTEXITCODE -ne 0) { throw "Pixel Streaming Infrastructure clone failed." }
}

$Signal = Join-Path $Infra "SignallingWebServer\platform_scripts\cmd\start.bat"
if (-not (Test-Path $Signal)) { throw "Pixel Streaming signalling server script not found: $Signal" }

Write-Host "Starting Pixel Streaming signalling/web server..."
Start-Process -FilePath $Signal -WorkingDirectory (Split-Path $Signal -Parent)
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

Write-Host "HOMEWARD_UNREAL_RUNNING"
Write-Host "Browser player: http://127.0.0.1:$HttpPort"
Write-Host "Streamer websocket: ws://127.0.0.1:$StreamerPort"
Write-Host "PID: $($Game.Id)"
