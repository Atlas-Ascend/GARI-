param(
    [string]$ArchiveDir = "$PSScriptRoot\..\Build\PixelStreaming"
)

$ErrorActionPreference = 'Stop'
$ArchiveDir = [System.IO.Path]::GetFullPath($ArchiveDir)
$ProofDir = Join-Path $ArchiveDir 'HOMEWARD-PROOF'
$DigestPath = Join-Path $ProofDir 'HOMEWARD-WHOLE-PACKAGE-DIGEST.json'
$ReceiptPath = Join-Path $ProofDir 'HOMEWARD-PIXELSTREAM-RECEIPT.json'

function Read-JsonFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Missing proof file: $Path" }
    return Get-Content -Raw -Path $Path | ConvertFrom-Json
}

function Get-DeterministicPackageDigest {
    param([Parameter(Mandatory=$true)][string]$Root)

    $interestingExtensions = @('.exe', '.pak', '.ucas', '.utoc', '.umap', '.uasset', '.ini', '.dll')
    $files = Get-ChildItem -Path $Root -Recurse -File |
        Where-Object {
            $relative = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
            if ($relative -like 'HOMEWARD-PROOF/*' -or $relative -like 'HOMEWARD-PROOF\*') { return $false }
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

$Digest = Read-JsonFile -Path $DigestPath
$Receipt = Read-JsonFile -Path $ReceiptPath

if ($Receipt.receipt_type -ne 'HOMEWARD_UNREAL_PACKAGE_PIXELSTREAM_V1') {
    throw "Unexpected receipt_type: $($Receipt.receipt_type)"
}
if ($Receipt.state -ne 'HOMEWARD_UNREAL_RUNNING') {
    throw "Unexpected receipt state: $($Receipt.state)"
}
if ($Receipt.engine -ne 'Unreal Engine 5.8') {
    throw "Unexpected engine: $($Receipt.engine)"
}
if ($Receipt.whole_package_digest_algorithm -ne 'SHA256_OF_SORTED_FILE_HASH_RECORDS_V1') {
    throw "Unexpected digest algorithm: $($Receipt.whole_package_digest_algorithm)"
}
if ($Digest.algorithm -ne 'SHA256_OF_SORTED_FILE_HASH_RECORDS_V1') {
    throw "Unexpected digest file algorithm: $($Digest.algorithm)"
}

$Exe = Get-ChildItem -Path $ArchiveDir -Filter 'Homeward.exe' -Recurse | Select-Object -First 1
if (-not $Exe) { throw "Homeward.exe missing under $ArchiveDir" }
$ExeHash = (Get-FileHash -Algorithm SHA256 -Path $Exe.FullName).Hash.ToLowerInvariant()
if ($ExeHash -ne $Receipt.executable_sha256) {
    throw "Executable hash mismatch. actual=$ExeHash receipt=$($Receipt.executable_sha256)"
}

$ActualDigest = Get-DeterministicPackageDigest -Root $ArchiveDir
if ($ActualDigest.digest -ne $Digest.digest) {
    throw "Digest file mismatch. actual=$($ActualDigest.digest) recorded=$($Digest.digest)"
}
if ($ActualDigest.digest -ne $Receipt.whole_package_digest) {
    throw "Receipt digest mismatch. actual=$($ActualDigest.digest) receipt=$($Receipt.whole_package_digest)"
}
if ([int]$Receipt.whole_package_file_count -ne [int]$ActualDigest.file_count) {
    throw "File count mismatch. actual=$($ActualDigest.file_count) receipt=$($Receipt.whole_package_file_count)"
}

$Verification = [ordered]@{
    receipt_type = 'HOMEWARD_PACKAGE_PROOF_VERIFICATION_V1'
    state = 'HOMEWARD_PACKAGE_PROOF_VERIFIED'
    archive_dir = $ArchiveDir
    executable_sha256 = $ExeHash
    whole_package_digest = $ActualDigest.digest
    whole_package_file_count = $ActualDigest.file_count
    verified_receipt = 'HOMEWARD-PROOF/HOMEWARD-PIXELSTREAM-RECEIPT.json'
    verified_digest = 'HOMEWARD-PROOF/HOMEWARD-WHOLE-PACKAGE-DIGEST.json'
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
}

$VerificationPath = Join-Path $ProofDir 'HOMEWARD-PACKAGE-PROOF-VERIFICATION.json'
$Verification | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 $VerificationPath
Get-FileHash $VerificationPath -Algorithm SHA256 |
    ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $ProofDir 'HOMEWARD-PACKAGE-PROOF-VERIFICATION.sha256.json')

Write-Host "HOMEWARD_PACKAGE_PROOF_VERIFIED"
Write-Host "HOMEWARD_WHOLE_PACKAGE_DIGEST=$($ActualDigest.digest)"
