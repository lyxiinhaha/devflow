#!/usr/bin/env bash
# DevFlow 安装 / 更新脚本
#
# 远程安装（推荐）：
#   bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh)
#
# 本地安装：
#   bash install.sh [--platform <platform>] [--dir <project-dir>]
#
# 更新：
#   bash install.sh --update [--dir <project-dir>]
#   或：bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --update
#
# platform 可选值：cursor | codex | opencode | gemini | claude

set -e

# ── 常量 ──────────────────────────────────────────────────────────────────────

DEVFLOW_VERSION="3.3.0"
GITHUB_REPO="lyxiinhaha/devflow"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 运行模式判断 ───────────────────────────────────────────────────────────────
# 从本地运行时 BASH_SOURCE[0] 是脚本路径；curl 管道运行时为空或 bash
if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
  LOCAL_MODE=true
  DEVFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  LOCAL_MODE=false
  DEVFLOW_ROOT=""
fi

TARGET_DIR="$(pwd)"
PLATFORM=""
UPDATE_MODE=false
SKIP_WORKSPACE_QUESTIONS=false

# ── 参数解析 ──────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform) PLATFORM="$2"; shift 2 ;;
    --dir)      TARGET_DIR="$2"; shift 2 ;;
    --update)   UPDATE_MODE=true; shift ;;
    --skip-config) SKIP_WORKSPACE_QUESTIONS=true; shift ;;
    *) shift ;;
  esac
done

# ── 工具函数 ──────────────────────────────────────────────────────────────────

step()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}→${NC} $1"; }
info()  { echo -e "  ${CYAN}·${NC} $1"; }
fatal() { echo -e "\n${RED}✗ $1${NC}\n"; exit 1; }

# 下载单个文件：download_file <remote_path> <local_dest>
# remote_path 相对于 RAW_BASE，如 "plugins/devflow/commands/fix.md"
download_file() {
  local remote="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if command -v curl &>/dev/null; then
    curl -fsSL "${RAW_BASE}/${remote}" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -q "${RAW_BASE}/${remote}" -O "$dest"
  else
    fatal "需要 curl 或 wget，请先安装其中一个"
  fi
}

# 从本地或远程读取文件内容到 stdout
read_source() {
  local path="$1"   # 相对于仓库根目录，如 "plugins/devflow/commands/fix.md"
  if [[ "$LOCAL_MODE" == true ]]; then
    cat "${DEVFLOW_ROOT}/${path}"
  else
    if command -v curl &>/dev/null; then
      curl -fsSL "${RAW_BASE}/${path}"
    else
      wget -q -O- "${RAW_BASE}/${path}"
    fi
  fi
}

# 复制目录下所有文件（本地模式直接 cp，远程模式逐文件下载）
# copy_dir <src_dir_relative> <dest_dir_absolute> [glob]
copy_files_from_manifest() {
  local manifest="$1"   # 文件列表，每行一个相对路径
  local dest_base="$2"  # 目标根目录

  while IFS= read -r rel_path; do
    [[ -z "$rel_path" ]] && continue
    local filename
    filename="$(basename "$rel_path")"
    if [[ "$LOCAL_MODE" == true ]]; then
      cp "${DEVFLOW_ROOT}/${rel_path}" "${dest_base}/${filename}"
    else
      download_file "$rel_path" "${dest_base}/${filename}"
    fi
  done <<< "$manifest"
}

# ── 文件清单（远程模式用，与仓库目录结构严格对应）──────────────────────────────

COMMANDS_MANIFEST="
plugins/devflow/commands/analyze.md
plugins/devflow/commands/change.md
plugins/devflow/commands/checklist.md
plugins/devflow/commands/code.md
plugins/devflow/commands/continue.md
plugins/devflow/commands/design.md
plugins/devflow/commands/estimate.md
plugins/devflow/commands/fix.md
plugins/devflow/commands/init.md
plugins/devflow/commands/knowledge.md
plugins/devflow/commands/list.md
plugins/devflow/commands/onboard.md
plugins/devflow/commands/plan.md
plugins/devflow/commands/quick.md
plugins/devflow/commands/refactor.md
plugins/devflow/commands/retrospect.md
plugins/devflow/commands/review.md
plugins/devflow/commands/start.md
plugins/devflow/commands/switch.md
plugins/devflow/commands/sync.md
"

ASSETS_CONFIG_MANIFEST="
plugins/devflow/assets/config/ai-policy.json
plugins/devflow/assets/config/devflow.json
plugins/devflow/assets/config/repo-classification.json
plugins/devflow/assets/config/workspace.tpl.json
"

ASSETS_TEMPLATES_MANIFEST="
plugins/devflow/assets/templates/design.tpl.md
plugins/devflow/assets/templates/meta.tpl.json
plugins/devflow/assets/templates/progress.tpl.md
plugins/devflow/assets/templates/requirement.tpl.md
plugins/devflow/assets/templates/tasks.tpl.md
"

ASSETS_KNOWLEDGE_MANIFEST="
plugins/devflow/assets/templates/knowledge/bug-experience-cards.csv
"

# ── 标题 ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${BLUE}DevFlow v${DEVFLOW_VERSION} — AI 研发工作流${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$LOCAL_MODE" == true ]]; then
  echo -e "  模式：${CYAN}本地安装${NC}（${DEVFLOW_ROOT}）"
else
  echo -e "  模式：${CYAN}远程安装${NC}（从 GitHub 下载）"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 更新模式
# ═══════════════════════════════════════════════════════════════════════════════

if [[ "$UPDATE_MODE" == true ]]; then
  META_FILE="${TARGET_DIR}/.devflow/.devflow-install.json"

  if [[ ! -f "$META_FILE" ]]; then
    fatal "未找到安装记录（${META_FILE}）\n  请先在项目目录完成安装"
  fi

  INSTALLED_PLATFORM=$(python3 -c "import json; d=json.load(open('$META_FILE')); print(d.get('platform','unknown'))" 2>/dev/null || echo "unknown")

  echo -e "  平台：${GREEN}${INSTALLED_PLATFORM}${NC}"
  echo -e "  目录：${GREEN}${TARGET_DIR}${NC}"
  echo ""
  echo "正在更新命令文件..."

  # 本地模式：从仓库 git pull 后复制
  if [[ "$LOCAL_MODE" == true ]]; then
    git -C "$DEVFLOW_ROOT" pull --ff-only 2>/dev/null && step "仓库已更新" || warn "git pull 失败，使用当前本地版本"
  fi

  COMMANDS_DIR="${TARGET_DIR}/.devflow/commands"
  mkdir -p "$COMMANDS_DIR"
  copy_files_from_manifest "$COMMANDS_MANIFEST" "$COMMANDS_DIR"
  step "命令文件已更新（${COMMANDS_DIR}）"

  ASSETS_DST="${TARGET_DIR}/.devflow/config"
  mkdir -p "${ASSETS_DST}/templates/knowledge"
  copy_files_from_manifest "$ASSETS_CONFIG_MANIFEST"   "$ASSETS_DST"
  copy_files_from_manifest "$ASSETS_TEMPLATES_MANIFEST" "${ASSETS_DST}/templates"
  copy_files_from_manifest "$ASSETS_KNOWLEDGE_MANIFEST" "${ASSETS_DST}/templates/knowledge"
  step "配置模板已更新"

  # 更新适配器（仅 cursor 支持无损更新）
  if [[ "$INSTALLED_PLATFORM" == "cursor" ]]; then
    local_or_remote_copy() {
      if [[ "$LOCAL_MODE" == true ]]; then
        cp "${DEVFLOW_ROOT}/adapters/cursor/devflow.mdc" "${TARGET_DIR}/.cursor/rules/devflow.mdc"
      else
        download_file "adapters/cursor/devflow.mdc" "${TARGET_DIR}/.cursor/rules/devflow.mdc"
      fi
    }
    local_or_remote_copy
    step "Cursor Rules 已更新"
  else
    warn "${INSTALLED_PLATFORM} 适配器为追加写入，跳过自动更新（如需更新请手动替换）"
  fi

  # 更新元数据时间戳
  python3 - "$META_FILE" <<'PYEOF'
import json, sys, datetime
f = sys.argv[1]
with open(f) as fh: d = json.load(fh)
d['updatedAt'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
with open(f, 'w') as fh: json.dump(d, fh, indent=2, ensure_ascii=False)
PYEOF
  step "安装记录已更新"

  echo ""
  echo -e "${GREEN}${BOLD}✅ DevFlow 更新完成！${NC}"
  echo ""
  exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 安装模式
# ═══════════════════════════════════════════════════════════════════════════════

# ── Step 1：选择平台 ──────────────────────────────────────────────────────────

detect_platform() {
  # 按优先级自动检测已有配置
  [[ -d "${TARGET_DIR}/.cursor" ]]                                    && echo "cursor"   && return
  [[ -f "${TARGET_DIR}/AGENTS.md" ]]                                  && echo "codex"    && return
  [[ -f "${TARGET_DIR}/OPENCODE.md" ]]                                && echo "opencode" && return
  [[ -f "${TARGET_DIR}/GEMINI.md" ]]                                  && echo "gemini"   && return
  # Claude Code：检查 .claude 目录或 claude CLI
  [[ -d "${TARGET_DIR}/.claude" ]] || command -v claude &>/dev/null   && echo "claude"   && return
  echo ""
}

if [[ -z "$PLATFORM" ]]; then
  DETECTED="$(detect_platform)"

  if [[ -n "$DETECTED" ]]; then
    echo -e "  检测到平台：${GREEN}${BOLD}${DETECTED}${NC}"
    read -rp "  使用此平台？[Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      DETECTED=""
    else
      PLATFORM="$DETECTED"
    fi
    echo ""
  fi

  if [[ -z "$PLATFORM" ]]; then
    echo "  请选择 AI 平台："
    echo "    1) Claude Code（推荐）"
    echo "    2) Cursor"
    echo "    3) Codex（OpenAI）"
    echo "    4) OpenCode"
    echo "    5) Gemini CLI"
    echo ""
    while true; do
      read -rp "  请输入编号 [1-5]：" choice
      case $choice in
        1) PLATFORM="claude"   ; break ;;
        2) PLATFORM="cursor"   ; break ;;
        3) PLATFORM="codex"    ; break ;;
        4) PLATFORM="opencode" ; break ;;
        5) PLATFORM="gemini"   ; break ;;
        *) echo "  请输入 1-5" ;;
      esac
    done
    echo ""
  fi
fi

echo -e "  平台：${GREEN}${BOLD}${PLATFORM}${NC}"
echo -e "  目录：${GREEN}${TARGET_DIR}${NC}"
echo ""

# ── Step 2：安装命令文件 ──────────────────────────────────────────────────────

echo "正在安装命令文件..."

COMMANDS_DIR="${TARGET_DIR}/.devflow/commands"
mkdir -p "$COMMANDS_DIR"

if [[ "$LOCAL_MODE" == true ]]; then
  cp "${DEVFLOW_ROOT}/plugins/devflow/commands/"*.md "$COMMANDS_DIR/"
else
  copy_files_from_manifest "$COMMANDS_MANIFEST" "$COMMANDS_DIR"
fi
step "命令文件 → .devflow/commands/ （20 个）"

# ── Step 3：安装资源文件 ──────────────────────────────────────────────────────

ASSETS_DST="${TARGET_DIR}/.devflow/config"
mkdir -p "${ASSETS_DST}/templates/knowledge"

if [[ "$LOCAL_MODE" == true ]]; then
  ASSETS_SRC="${DEVFLOW_ROOT}/plugins/devflow/assets"
  cp "${ASSETS_SRC}/config/"*.json  "$ASSETS_DST/"                      2>/dev/null || true
  cp "${ASSETS_SRC}/templates/"*.md "$ASSETS_DST/templates/"            2>/dev/null || true
  cp "${ASSETS_SRC}/templates/"*.json "$ASSETS_DST/templates/"          2>/dev/null || true
  cp "${ASSETS_SRC}/templates/knowledge/"* "$ASSETS_DST/templates/knowledge/" 2>/dev/null || true
else
  copy_files_from_manifest "$ASSETS_CONFIG_MANIFEST"    "$ASSETS_DST"
  copy_files_from_manifest "$ASSETS_TEMPLATES_MANIFEST" "${ASSETS_DST}/templates"
  copy_files_from_manifest "$ASSETS_KNOWLEDGE_MANIFEST" "${ASSETS_DST}/templates/knowledge"
fi
step "配置模板 → .devflow/config/"

# ── Step 4：初始化 workspace.json ─────────────────────────────────────────────

WORKSPACE="${TARGET_DIR}/.devflow/workspace.json"
if [[ ! -f "$WORKSPACE" ]]; then
  if [[ "$LOCAL_MODE" == true ]]; then
    cp "${DEVFLOW_ROOT}/plugins/devflow/assets/config/workspace.tpl.json" "$WORKSPACE"
  else
    download_file "plugins/devflow/assets/config/workspace.tpl.json" "$WORKSPACE"
  fi
  step "workspace.json 已初始化"
else
  warn "workspace.json 已存在，跳过"
fi

# ── Step 5：安装平台适配器 ────────────────────────────────────────────────────

echo ""
echo "正在安装平台适配器..."

install_adapter_file() {
  local rel_path="$1"   # 相对仓库根的路径
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ "$LOCAL_MODE" == true ]]; then
    cp "${DEVFLOW_ROOT}/${rel_path}" "$dest"
  else
    download_file "$rel_path" "$dest"
  fi
}

append_adapter_file() {
  local rel_path="$1"
  local dest="$2"
  local content
  content="$(read_source "$rel_path")"
  if [[ -f "$dest" ]]; then
    echo "" >> "$dest"; echo "---" >> "$dest"; echo "" >> "$dest"
    echo "$content" >> "$dest"
  else
    echo "$content" > "$dest"
  fi
}

case $PLATFORM in
  claude)
    echo ""
    echo -e "  ${YELLOW}Claude Code 使用官方插件机制，请在安装完成后执行：${NC}"
    echo ""
    if [[ "$LOCAL_MODE" == true ]]; then
      echo -e "    ${CYAN}claude plugins install ${DEVFLOW_ROOT}/plugins/devflow${NC}"
    else
      echo -e "    ${CYAN}claude plugins install https://github.com/${GITHUB_REPO}${NC}"
    fi
    echo ""
    warn "平台适配器已跳过（插件机制自动处理）"
    ;;
  cursor)
    install_adapter_file "adapters/cursor/devflow.mdc" "${TARGET_DIR}/.cursor/rules/devflow.mdc"
    step "Cursor Rules → .cursor/rules/devflow.mdc"
    ;;
  codex)
    append_adapter_file "adapters/codex/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
    step "DevFlow 配置 → AGENTS.md"
    ;;
  opencode)
    append_adapter_file "adapters/opencode/OPENCODE.md" "${TARGET_DIR}/OPENCODE.md"
    step "DevFlow 配置 → OPENCODE.md"
    ;;
  gemini)
    append_adapter_file "adapters/gemini/GEMINI.md" "${TARGET_DIR}/GEMINI.md"
    step "DevFlow 配置 → GEMINI.md"
    ;;
esac

# ── Step 6：交互式配置 workspace.json ─────────────────────────────────────────

if [[ "$SKIP_WORKSPACE_QUESTIONS" == false ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}  基础配置（可选，直接回车跳过）${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # YApi 地址
  echo -e "  ${CYAN}[1/3] YApi 接口文档${NC}"
  echo "  analyze / design 命令会自动查询 YApi，无需每次粘贴链接"
  read -rp "  YApi 域名（如 yapi.example.com）：" YAPI_HOST
  echo ""

  # Meegle 项目
  echo -e "  ${CYAN}[2/3] Meegle（飞书项目）${NC}"
  echo "  配置后 devflow fix 可直接读取 issue 详情，工作项状态自动同步"
  read -rp "  Meegle 项目 Key（如 PROJ）：" MEEGLE_PROJECT_KEY
  echo ""

  # 验收清单 Skill
  echo -e "  ${CYAN}[3/3] 专项验收清单 Skill${NC}"
  echo "  devflow checklist 会优先使用此 Skill 生成验收清单"
  read -rp "  Skill 名称（如 my-acceptance-checklist）：" CHECKLIST_SKILL
  echo ""

  # 写入 workspace.json
  python3 - "$WORKSPACE" "$YAPI_HOST" "$MEEGLE_PROJECT_KEY" "$CHECKLIST_SKILL" <<'PYEOF'
import json, sys
workspace_path, yapi_host, meegle_key, checklist_skill = sys.argv[1:]

with open(workspace_path) as f:
    d = json.load(f)

if yapi_host.strip():
    d.setdefault('integrations', {})['yapiHost'] = yapi_host.strip()
if meegle_key.strip():
    d.setdefault('meegle', {})['projectKey'] = meegle_key.strip()
if checklist_skill.strip():
    d['checklistSkill'] = checklist_skill.strip()

with open(workspace_path, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
PYEOF

  step "workspace.json 已更新"
fi

# ── Step 7：写入 .gitignore ───────────────────────────────────────────────────

echo ""
echo "正在更新 .gitignore..."

GITIGNORE="${TARGET_DIR}/.gitignore"
DEVFLOW_IGNORE="# DevFlow workspace (local only)
.devflow/workspace.json
.devflow/work-items/
.devflow/.devflow-install.json
.codegraph/"

if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q ".devflow/workspace.json" "$GITIGNORE"; then
    { echo ""; echo "$DEVFLOW_IGNORE"; } >> "$GITIGNORE"
    step ".gitignore 已追加 DevFlow 条目"
  else
    warn ".gitignore 已包含 DevFlow 条目，跳过"
  fi
else
  echo "$DEVFLOW_IGNORE" > "$GITIGNORE"
  step ".gitignore 已创建"
fi

# ── Step 8：写入安装元数据 ────────────────────────────────────────────────────

META_FILE="${TARGET_DIR}/.devflow/.devflow-install.json"
INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

python3 - "$META_FILE" "$PLATFORM" "$DEVFLOW_ROOT" "$INSTALLED_AT" "$GITHUB_REPO" <<'PYEOF'
import json, sys
meta_path, platform, devflow_root, installed_at, github_repo = sys.argv[1:]
d = {
    "platform": platform,
    "devflowRepo": devflow_root,
    "githubRepo": github_repo,
    "installedAt": installed_at,
    "updatedAt": installed_at
}
with open(meta_path, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
PYEOF
step "安装记录 → .devflow/.devflow-install.json"

# ═══════════════════════════════════════════════════════════════════════════════
# 完成
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}✅ DevFlow 安装完成！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  ${BOLD}下一步：${NC}"
echo ""

if [[ "$PLATFORM" == "claude" ]]; then
  if [[ "$LOCAL_MODE" == true ]]; then
    echo -e "  ${CYAN}1.${NC} 安装 Claude Code 插件："
    echo -e "     ${BOLD}claude plugins install ${DEVFLOW_ROOT}/plugins/devflow${NC}"
  else
    echo -e "  ${CYAN}1.${NC} 安装 Claude Code 插件："
    echo -e "     ${BOLD}claude plugins install https://github.com/${GITHUB_REPO}${NC}"
  fi
  echo ""
  echo -e "  ${CYAN}2.${NC} 用 Claude Code 打开项目，输入："
  echo -e "     ${BOLD}devflow init${NC}"
else
  echo -e "  ${CYAN}1.${NC} 用 ${PLATFORM^} 打开项目，输入："
  echo -e "     ${BOLD}devflow init${NC}"
fi

echo ""
echo -e "  init 会自动检测技术栈、配置 CodeGraph、生成 Review Skill。"
echo ""
echo -e "  ${BOLD}以后更新 DevFlow：${NC}"
echo -e "  bash <(curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh) --update"
echo ""
