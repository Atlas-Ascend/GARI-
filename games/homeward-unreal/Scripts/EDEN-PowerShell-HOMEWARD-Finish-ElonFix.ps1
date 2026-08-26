# Ghost Atlas HOMEWARD EDEN PowerShell ElonFix wrapper
# Fixes PowerShell variable-scope parser issue in the current finisher, then executes it.

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

$SourceUrl = 'https://raw.githubusercontent.com/Atlas-Ascend/GARI-/build/new-atlantis-homeward-unreal-5.8/games/homeward-unreal/Scripts/EDEN-PowerShell-HOMEWARD-Finish.ps1'
Write-Host 'Downloading EDEN HOMEWARD finisher...'
$Script = (Invoke-WebRequest -UseBasicParsing -Uri $SourceUrl).Content

# PowerShell parses "$UserName:" as a scoped variable. Convert to braced variable syntax before parsing.
$Script = $Script.Replace('$UserName:(OI)(CI)F', '${UserName}:(OI)(CI)F')
$Script = $Script.Replace('$UserName:F', '${UserName}:F')

$FixedPath = 'C:\Ghost\RUNS\EDEN-HOMEWARD-ElonFix-Fixed.ps1'
New-Item -ItemType Directory -Force -Path (Split-Path $FixedPath -Parent) | Out-Null
Set-Content -Encoding utf8 -Path $FixedPath -Value $Script
Write-Host "Fixed script written: $FixedPath"

& $FixedPath -UserName $UserName -ArkPublicKey $ArkPublicKey -RepoUrl $RepoUrl -Branch $Branch -RepoRoot $RepoRoot -WaitForUEHours $WaitForUEHours
