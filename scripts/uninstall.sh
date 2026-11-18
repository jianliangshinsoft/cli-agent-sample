#!/usr/bin/env bash
# filecli 卸载脚本（macOS / Linux）
# 用法: curl -fsSL https://raw.githubusercontent.com/jianliangshinsoft/cli-agent-sample/master/scripts/uninstall.sh | bash
set -euo pipefail

BIN_DIR="${FILECLI_INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$BIN_DIR/filecli"

# 删除二进制（install.sh 不修改 PATH，无需清理）
if [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  echo "已删除 $TARGET"
else
  echo "未找到 $TARGET（可能已卸载）"
fi

# 若安装时设置了 FILECLI_INSTALL_DIR，此时目录可能已空，顺带清理空目录
if [ -d "$BIN_DIR" ] && [ -z "$(ls -A "$BIN_DIR")" ]; then
  rmdir "$BIN_DIR"
  echo "已删除空目录 $BIN_DIR"
fi

echo "filecli 已卸载。如之前手动把 $BIN_DIR 加入了 PATH，可自行决定是否移除该配置。"
echo "如果当初是用 dotnet tool 安装的，卸载命令为: dotnet tool uninstall --global FileCli.Demo"
