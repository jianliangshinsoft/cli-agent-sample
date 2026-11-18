# filecli uninstaller for Windows (PowerShell 5.1+)
# Usage: irm https://raw.githubusercontent.com/jianliangshinsoft/cli-agent-sample/master/scripts/uninstall.ps1 | iex
# Or run locally: ./uninstall.ps1
# NOTE: Keep this file pure ASCII (no non-English characters). Piping through irm|iex
#       on PS 5.1 decodes the response with the system ANSI codepage, which garbles
#       UTF-8 text and can break parsing. English-only scripts are safe everywhere.
$ErrorActionPreference = "Stop"

$BinDir = "$env:LOCALAPPDATA\Programs\filecli"

# 1. Remove the installed binary (the whole install folder)
if (Test-Path $BinDir) {
    Remove-Item $BinDir -Recurse -Force
    Write-Host "Removed $BinDir"
} else {
    Write-Host "Not found: $BinDir (already uninstalled?)"
}

# 2. Remove the install folder from the user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not [string]::IsNullOrEmpty($userPath)) {
    $parts = $userPath.Split(";") | Where-Object { $_ -and $_.TrimEnd("\") -ne $BinDir.TrimEnd("\") }
    $newPath = ($parts -join ";")
    if ($newPath -ne $userPath) {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Removed $BinDir from user PATH"
    } else {
        Write-Host "$BinDir was not in user PATH"
    }
}

Write-Host "filecli uninstalled. Note: the change to PATH takes effect in NEW terminals."
Write-Host "If installed via dotnet tool instead, run: dotnet tool uninstall --global FileCli.Demo"
