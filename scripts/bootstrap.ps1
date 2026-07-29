[CmdletBinding()]
param(
    [string]$CaseId = "LSC-OR-CLATSOP-001",
    [switch]$SkipGitHub
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

Write-Host "GARI LANTERN Genesis bootstrap" -ForegroundColor Cyan
Assert-Command git
Assert-Command python

if (-not $SkipGitHub) {
    Assert-Command gh
    gh auth status
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI is not authenticated. Run 'gh auth login' and retry."
    }
}

$version = python -c "import sys; print('.'.join(map(str, sys.version_info[:3])))"
Write-Host "Python $version"
python -c "import sys; raise SystemExit(0 if sys.version_info >= (3,12) else 1)"
if ($LASTEXITCODE -ne 0) {
    throw "Python 3.12 or newer is required."
}

if (-not (Test-Path ".venv")) {
    python -m venv .venv
}

$python = Join-Path $PWD ".venv\Scripts\python.exe"
$lantern = Join-Path $PWD ".venv\Scripts\lantern.exe"
$pytest = Join-Path $PWD ".venv\Scripts\pytest.exe"
$ruff = Join-Path $PWD ".venv\Scripts\ruff.exe"
$mypy = Join-Path $PWD ".venv\Scripts\mypy.exe"

& $python -m pip install --upgrade pip
& $python -m pip install -e ".[dev]"

& $ruff check .
& $mypy
& $pytest -q
& $lantern generate-schema
& $lantern validate $CaseId
& $lantern build-public $CaseId

if (-not (Test-Path "site\data\case.json")) {
    throw "Public case artifact was not generated."
}

Write-Host "" 
Write-Host "COMMAND-TO-PROOF PASS" -ForegroundColor Green
Write-Host "Case: $CaseId"
Write-Host "Preview: & '$python' -m http.server 8000 --directory site"
Write-Host "Website: http://localhost:8000"
Write-Host "Publication authority remains controlled by the case and release gates."
