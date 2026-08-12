#!/usr/bin/env bash
# DevFlow 安装脚本
# 用法：bash install.sh [--platform <platform>] [--dir <project-dir>]
#
# platform 可选值：cursor | codex | opencode | gemini | claude
# 不传 platform 时交互式询问
# --dir 指定安装到的项目目录，默认为当前目录

set -e

DEVFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"
PLATFORM=""

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}DevFlow v3.3.0 — AI 研发工作流安装程序${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 选择平台
if [[ -z "$PLATFORM" ]]; then
  echo "请选择 AI 平台："
  echo "  1) Claude Code（claude plugins install，推荐）"
  echo "  2) Cursor"
  echo "  3) Codex（OpenAI）"
  echo "  4) OpenCode"
  echo "  5) Gemini CLI"
  echo "  6) 通用（仅复制命令文件，手动配置适配器）"
  echo ""
  read -rp "请输入编号 [1-6]：" choice
  case $choice in
    1) PLATFORM="claude" ;;
    2) PLATFORM="cursor" ;;
    3) PLATFORM="codex" ;;
    4) PLATFORM="opencode" ;;
    5) PLATFORM="gemini" ;;
    6) PLATFORM="generic" ;;
    *) echo "无效选项，退出。"; exit 1 ;;
  esac
fi

echo -e "平台：${GREEN}${PLATFORM}${NC}"
echo -e "目标目录：${GREEN}${TARGET_DIR}${NC}"
echo ""

# Claude Code — 使用官方插件机制，不需要脚本安装
if [[ "$PLATFORM" == "claude" ]]; then
  echo -e "${YELLOW}Claude Code 请使用官方安装方式：${NC}"
  echo ""
  echo "  claude plugins install devflow"
  echo ""
  echo "或从本地安装（当前仓库）："
  echo ""
  echo "  claude plugins install ${DEVFLOW_ROOT}/plugins/devflow"
  echo ""
  exit 0
fi

# 创建 .devflow/commands 目录
COMMANDS_DIR="${TARGET_DIR}/.devflow/commands"
mkdir -p "$COMMANDS_DIR"

# 复制所有命令文件
echo "正在复制命令文件..."
cp "${DEVFLOW_ROOT}/plugins/devflow/commands/"*.md "$COMMANDS_DIR/"
echo -e "  ${GREEN}✓${NC} 命令文件已复制到 .devflow/commands/"

# 复制资源文件
ASSETS_SRC="${DEVFLOW_ROOT}/plugins/devflow/assets"
ASSETS_DST="${TARGET_DIR}/.devflow/config"
mkdir -p "$ASSETS_DST/templates/knowledge"
cp "${ASSETS_SRC}/config/"*.json "$ASSETS_DST/" 2>/dev/null || true
cp "${ASSETS_SRC}/templates/"*.md "$ASSETS_DST/templates/" 2>/dev/null || true
cp "${ASSETS_SRC}/templates/"*.json "$ASSETS_DST/templates/" 2>/dev/null || true
cp "${ASSETS_SRC}/templates/knowledge/"* "$ASSETS_DST/templates/knowledge/" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} 配置模板已复制到 .devflow/config/"

# 初始化 workspace.json（如不存在）
WORKSPACE="${TARGET_DIR}/.devflow/workspace.json"
if [[ ! -f "$WORKSPACE" ]]; then
  cp "${ASSETS_SRC}/config/workspace.tpl.json" "$WORKSPACE"
  echo -e "  ${GREEN}✓${NC} workspace.json 已初始化"
else
  echo -e "  ${YELLOW}→${NC} workspace.json 已存在，跳过"
fi

# 安装平台适配器
echo ""
echo "正在安装平台适配器..."

case $PLATFORM in
  cursor)
    CURSOR_DIR="${TARGET_DIR}/.cursor/rules"
    mkdir -p "$CURSOR_DIR"
    cp "${DEVFLOW_ROOT}/adapters/cursor/devflow.mdc" "$CURSOR_DIR/"
    echo -e "  ${GREEN}✓${NC} Cursor 规则已写入 .cursor/rules/devflow.mdc"
    ;;

  codex)
    AGENTS_FILE="${TARGET_DIR}/AGENTS.md"
    ADAPTER="${DEVFLOW_ROOT}/adapters/codex/AGENTS.md"
    if [[ -f "$AGENTS_FILE" ]]; then
      echo "" >> "$AGENTS_FILE"
      echo "---" >> "$AGENTS_FILE"
      echo "" >> "$AGENTS_FILE"
      cat "$ADAPTER" >> "$AGENTS_FILE"
      echo -e "  ${GREEN}✓${NC} DevFlow 配置已追加到现有 AGENTS.md"
    else
      cp "$ADAPTER" "$AGENTS_FILE"
      echo -e "  ${GREEN}✓${NC} AGENTS.md 已创建"
    fi
    ;;

  opencode)
    OPENCODE_FILE="${TARGET_DIR}/OPENCODE.md"
    ADAPTER="${DEVFLOW_ROOT}/adapters/opencode/OPENCODE.md"
    if [[ -f "$OPENCODE_FILE" ]]; then
      echo "" >> "$OPENCODE_FILE"
      echo "---" >> "$OPENCODE_FILE"
      echo "" >> "$OPENCODE_FILE"
      cat "$ADAPTER" >> "$OPENCODE_FILE"
      echo -e "  ${GREEN}✓${NC} DevFlow 配置已追加到现有 OPENCODE.md"
    else
      cp "$ADAPTER" "$OPENCODE_FILE"
      echo -e "  ${GREEN}✓${NC} OPENCODE.md 已创建"
    fi
    ;;

  gemini)
    GEMINI_FILE="${TARGET_DIR}/GEMINI.md"
    ADAPTER="${DEVFLOW_ROOT}/adapters/gemini/GEMINI.md"
    if [[ -f "$GEMINI_FILE" ]]; then
      echo "" >> "$GEMINI_FILE"
      echo "---" >> "$GEMINI_FILE"
      echo "" >> "$GEMINI_FILE"
      cat "$ADAPTER" >> "$GEMINI_FILE"
      echo -e "  ${GREEN}✓${NC} DevFlow 配置已追加到现有 GEMINI.md"
    else
      cp "$ADAPTER" "$GEMINI_FILE"
      echo -e "  ${GREEN}✓${NC} GEMINI.md 已创建"
    fi
    ;;

  generic)
    echo -e "  ${YELLOW}→${NC} 通用模式：命令文件已复制，请手动配置适配器"
    echo "    适配器模板位于：${DEVFLOW_ROOT}/adapters/"
    ;;
esac

# 更新 .gitignore
GITIGNORE="${TARGET_DIR}/.gitignore"
DEVFLOW_IGNORE="# DevFlow workspace (local only)
.devflow/workspace.json
.devflow/work-items/
.codegraph/"

if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q ".devflow/workspace.json" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "$DEVFLOW_IGNORE" >> "$GITIGNORE"
    echo -e "  ${GREEN}✓${NC} .gitignore 已更新"
  else
    echo -e "  ${YELLOW}→${NC} .gitignore 已包含 DevFlow 条目，跳过"
  fi
else
  echo "$DEVFLOW_IGNORE" > "$GITIGNORE"
  echo -e "  ${GREEN}✓${NC} .gitignore 已创建"
fi

echo ""
echo -e "${GREEN}✅ DevFlow 安装完成！${NC}"
echo ""
echo "下一步："
echo "  1. 在你的 AI 工具中打开项目"
echo "  2. 输入：devflow init"
echo "  3. 按提示完成初始化（配置 CodeGraph、可选集成等）"
echo ""
