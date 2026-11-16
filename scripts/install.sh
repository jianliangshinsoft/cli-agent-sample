#!/usr/bin/env bash
# filecli 一键安装脚本（macOS / Linux）
# 用法: curl -fsSL https://raw.githubusercontent.com/jianliangshinsoft/cli-agent-sample/master/scripts/install.sh | bash
set -euo pipefail

REPO="jianliangshinsoft/cli-agent-sample"   # 发布后替换为实际 GitHub 仓库
BIN_DIR="${FILECLI_INSTALL_DIR:-$HOME/.local/bin}"

# 1. 识别平台 → Release 资产名
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Linux*)  platform="linux" ;;
  Darwin*) platform="osx" ;;
  *) echo "不支持的操作系统: $os" >&2; exit 1 ;;
esac
case "$arch" in
  x86_64)  platform="${platform}-x64" ;;
  aarch64|arm64) platform="${platform}-arm64" ;;
  *) echo "不支持的架构: $arch" >&2; exit 1 ;;
esac

# 2. 下载归档与校验和到临时目录
archive="filecli-${platform}.tar.gz"
base="https://github.com/${REPO}/releases/latest/download"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "下载 $base/$archive"
curl -fsSL "$base/$archive" -o "$tmp/$archive"
curl -fsSL "$base/$archive.sha256" -o "$tmp/$archive.sha256"

# 3. SHA256 完整性校验（防下载损坏与被篡改的二进制）
expected="$(cut -d' ' -f1 "$tmp/$archive.sha256" | tr 'A-Z' 'a-z')"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$tmp/$archive" | cut -d' ' -f1)"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$tmp/$archive" | cut -d' ' -f1)"
else
  echo "错误: 系统缺少 sha256sum / shasum，无法校验完整性" >&2
  exit 1
fi
if [ "$actual" != "$expected" ]; then
  echo "错误: SHA256 校验失败！" >&2
  echo "  期望: $expected" >&2
  echo "  实际: $actual" >&2
  echo "下载的文件可能已损坏或被篡改，已中止安装。" >&2
  exit 1
fi
echo "SHA256 校验通过: $actual"

# 4. 解压并安装到用户 bin 目录
tar xzf "$tmp/$archive" -C "$tmp"
mkdir -p "$BIN_DIR"
install -m 755 "$tmp/filecli" "$BIN_DIR/filecli"
echo "已安装到 $BIN_DIR/filecli"
echo "$PATH" | grep -q "$BIN_DIR" || echo "提示: 请将 $BIN_DIR 加入 PATH（写入 ~/.bashrc 或 ~/.zshrc）"
echo "验证: filecli --help"