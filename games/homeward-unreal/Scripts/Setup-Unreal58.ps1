param(
    [string]$EngineDir = "$PSScriptRoot\..\.ue\UnrealEngine-5.8",
    [string]$EngineRepo = "git@github.com:EpicGames/UnrealEngine.git",
    [string]$EngineBranch = "5.8"
)

$ErrorActionPreference = "Stop"
$EngineDir = [System.IO.Path]::GetFullPath($EngineDir)

if (Test-Path "$EngineDir\Engine\Build\BatchFiles\Build.bat") {
    Write-Host "UE 5.8 already present: $EngineDir"
    exit 0
}

Write-Host "Checking EpicGames/UnrealEngine access..."
& git ls-remote $EngineRepo HEAD | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Epic Unreal GitHub access is not available. Link the GitHub account to an Epic account and accept the Unreal EULA first."
}

New-Item -ItemType Directory -Force -Path (Split-Path $EngineDir -Parent) | Out-Null
& git clone --branch $EngineBranch --single-branch $EngineRepo $EngineDir
if ($LASTEXITCODE -ne 0) { throw "Unreal Engine clone failed." }

Push-Location $EngineDir
try {
    & .\Setup.bat
    if ($LASTEXITCODE -ne 0) { throw "Setup.bat failed." }

    & .\GenerateProjectFiles.bat
    if ($LASTEXITCODE -ne 0) { throw "GenerateProjectFiles.bat failed." }

    & .\Engine\Build\BatchFiles\Build.bat UnrealEditor Win64 Development -WaitMutex -NoHotReloadFromIDE
    if ($LASTEXITCODE -ne 0) { throw "UnrealEditor build failed." }
}
finally {
    Pop-Location
}

Write-Host "UE 5.8 READY: $EngineDir"
