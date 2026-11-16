# filecli 一键安装脚本（Windows PowerShell）
# 用法: irm https://raw.githubusercontent.com/jianliangshinsoft/cli-agent-sample/master/scripts/install.ps1 | iex
$ErrorActionPreference = "Stop"

$Repo = "jianliangshinsoft/cli-agent-sample"   # 发布后替换为实际 GitHub 仓库
$BinDir = "$env:LOCALAPPDATA\Programs\filecli"

# 1. 识别架构 -> Release 资产名
$arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64"  { "x64" }
    "ARM64"  { "arm64" }
    default  { throw "不支持的架构: $env:PROCESSOR_ARCHITECTURE" }
}
$asset = "filecli-win-$arch.zip"

# 2. 下载归档与校验和
$tmp = Join-Path $env:TEMP ("filecli-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
$base = "https://github.com/$Repo/releases/latest/download"
Write-Host "下载 $base/$asset"
$zip = Join-Path $tmp $asset
Invoke-WebRequest -Uri "$base/$asset" -OutFile $zip
Invoke-WebRequest -Uri "$base/$asset.sha256" -OutFile "$zip.sha256"

# 3. SHA256 完整性校验（防下载损坏与被篡改的二进制）
$expected = ((Get-Content "$zip.sha256" -TotalCount 1) -split '\s+')[0].ToLower()
$actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
if ($expected -ne $actual) {
    Remove-Item $tmp -Recurse -Force
    throw "SHA256 校验失败！期望 $expected，实际 $actual。下载的文件可能已损坏或被篡改，已中止安装。"
}
Write-Host "SHA256 校验通过: $actual"

# 4. 解压
Expand-Archive -Path $zip -DestinationPath $tmp -Force

# 3. 安装到用户目录并加入 PATH
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
Copy-Item (Join-Path $tmp "filecli.exe") $BinDir -Force
Remove-Item $tmp -Recurse -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$BinDir", "User")
    Write-Host "已将 $BinDir 加入用户 PATH（重开终端生效）"
}

Write-Host "已安装到 $BinDir\filecli.exe"
Write-Host "验证: filecli --help"
