# filecli installer for Windows (PowerShell 5.1+)
# Usage: irm https://raw.githubusercontent.com/jianliangshinsoft/cli-agent-sample/master/scripts/install.ps1 | iex
# NOTE: Keep this file pure ASCII (no non-English characters). Piping through irm|iex
#       on PS 5.1 decodes the response with the system ANSI codepage, which garbles
#       UTF-8 text and can break parsing. English-only scripts are safe everywhere.
$ErrorActionPreference = "Stop"

$Repo = "jianliangshinsoft/cli-agent-sample"
$BinDir = "$env:LOCALAPPDATA\Programs\filecli"

# 1. Detect architecture -> Release asset name
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64"  { "x64" }
    "ARM64"  { "arm64" }
    default  { throw "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
}
$asset = "filecli-win-$arch.zip"

# 2. Download archive and checksum
$tmp = Join-Path $env:TEMP ("filecli-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
$base = "https://github.com/$Repo/releases/latest/download"
Write-Host "Downloading $base/$asset"
$zip = Join-Path $tmp $asset
Invoke-WebRequest -Uri "$base/$asset" -OutFile $zip
Invoke-WebRequest -Uri "$base/$asset.sha256" -OutFile "$zip.sha256"

# 3. Verify SHA256 integrity (guards against corrupted or tampered binaries)
$expected = ((Get-Content "$zip.sha256" -TotalCount 1) -split '\s+')[0].ToLower()
$actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
if ($expected -ne $actual) {
    Remove-Item $tmp -Recurse -Force
    throw "SHA256 verification FAILED! expected $expected, got $actual. The download may be corrupted or tampered. Installation aborted."
}
Write-Host "SHA256 verified: $actual"

# 4. Extract
Expand-Archive -Path $zip -DestinationPath $tmp -Force

# 5. Install to user directory and add to PATH
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
Copy-Item (Join-Path $tmp "filecli.exe") $BinDir -Force
Remove-Item $tmp -Recurse -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrEmpty($userPath)) { $userPath = "" }
if ($userPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$BinDir", "User")
    Write-Host "Added $BinDir to user PATH (reopen terminal to take effect)"
}

Write-Host "Installed to $BinDir\filecli.exe"
Write-Host "Verify: filecli --help"
