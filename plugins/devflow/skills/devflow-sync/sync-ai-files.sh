#!/usr/bin/env bash
set -euo pipefail

# 将 devflow 插件包中维护的团队公共 AI 文件同步到目标项目。
#
# 执行内容：
#   1. 将公共 skills / agents 复制到目标项目 .ai/ 目录
#   2. 在 .claude / .codex 下创建指向 .ai/ 的软链接
#   3. 在目标项目 .gitignore 中维护个人 AI 配置忽略规则
#   4. 若个人 AI 配置已被 Git 跟踪，从 Git index 移除（保留本地文件）
#
# 源目录（devflow 插件包）：
#   <devflow-plugin>/ai-files/skills/<skill-name>
#   <devflow-plugin>/ai-files/agents/<agent-name>
#
# 目标目录（项目内）：
#   <project>/.ai/skills/<skill-name>
#   <project>/.ai/agents/<agent-name>
#
# 软链接：
#   <project>/.claude/skills/<skill-name>  -> ../../.ai/skills/<skill-name>
#   <project>/.codex/skills/<skill-name>   -> ../../.ai/skills/<skill-name>
#   <project>/.claude/agents/<agent-name>  -> ../../.ai/agents/<agent-name>
#   <project>/.codex/agents/<agent-name>   -> ../../.ai/agents/<agent-name>
#
# 用法：
#   ./sync-ai-files.sh [target-project-root]
#
# 未传 target-project-root 时，默认使用当前工作目录。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 颜色输出 ─────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*" >&2; }

# ── 解析 devflow 插件的 ai-files 源目录 ──────────────────
# 兼容两种场景：
#   1. 源仓库检出：脚本某个祖先目录下有 ai-files/skills
#   2. 插件缓存安装：从 .../plugins/cache/... 回退到
#      .../plugins/marketplaces/.../ai-files
resolve_source_dir() {
  local dir="${SCRIPT_DIR}"
  while [[ "${dir}" != "/" ]]; do
    if [[ -d "${dir}/ai-files/skills" ]]; then
      printf '%s\n' "${dir}/ai-files"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done

  # 插件缓存路径回退
  if [[ "${SCRIPT_DIR}" == *"/plugins/cache/"* ]]; then
    local plugins_root="${SCRIPT_DIR%%/plugins/cache/*}/plugins"
    local marketplace_rest="${SCRIPT_DIR#*/plugins/cache/}"
    local marketplace_name="${marketplace_rest%%/*}"
    local candidate="${plugins_root}/marketplaces/${marketplace_name}/ai-files"
    if [[ -d "${candidate}/skills" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi

  return 1
}

# ── 参数解析 ──────────────────────────────────────────────
TARGET_PROJECT="${1:-$(pwd)}"
TARGET_PROJECT="$(cd "${TARGET_PROJECT}" && pwd)"

# ── 源目录解析 ────────────────────────────────────────────
if ! SOURCE_DIR="$(resolve_source_dir)"; then
  err "无法定位 devflow ai-files 源目录。"
  err "请确认 devflow 插件已正确安装：claude plugins install devflow"
  exit 1
fi

SOURCE_SKILLS_DIR="${SOURCE_DIR}/skills"
SOURCE_AGENTS_DIR="${SOURCE_DIR}/agents"

echo ""
echo "DevFlow AI 文件同步"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  源目录：${SOURCE_DIR}"
echo "  目标项目：${TARGET_PROJECT}"
echo ""

# ── 同步函数 ──────────────────────────────────────────────
sync_entries() {
  local src_dir="$1"
  local dst_dir="$2"
  local kind="$3"   # "skills" 或 "agents"
  local count=0

  if [[ ! -d "${src_dir}" ]]; then
    warn "${kind} 源目录不存在，跳过：${src_dir}"
    return 0
  fi

  mkdir -p "${dst_dir}"

  for src_entry in "${src_dir}"/*/; do
    [[ -d "${src_entry}" ]] || continue
    local name
    name="$(basename "${src_entry}")"
    local dst_entry="${dst_dir}/${name}"

    # 复制/更新
    rm -rf "${dst_entry}"
    cp -r "${src_entry}" "${dst_entry}"
    ok "${kind}/${name}"
    count=$((count + 1))
  done

  echo "  → ${kind} 已同步：${count} 个"
  echo ""
}

# ── 创建软链接函数 ─────────────────────────────────────────
create_symlinks() {
  local ai_dir="$1"       # .ai/skills 或 .ai/agents
  local tool_dir="$2"     # .claude/skills 或 .codex/skills
  local kind="$3"

  [[ -d "${ai_dir}" ]] || return 0

  mkdir -p "${tool_dir}"

  for src_entry in "${ai_dir}"/*/; do
    [[ -d "${src_entry}" ]] || continue
    local name
    name="$(basename "${src_entry}")"
    local link="${tool_dir}/${name}"
    local rel_target

    # 计算相对路径（从 tool_dir 到 ai_dir）
    rel_target="$(python3 -c "
import os
print(os.path.relpath('${src_entry%/}', '${tool_dir}'))
" 2>/dev/null || echo "../../.ai/${kind}/${name}")"

    # 覆盖已有链接或同名目录（仅限软链接）
    if [[ -L "${link}" ]]; then
      rm "${link}"
    elif [[ -e "${link}" ]]; then
      warn "跳过 ${link}（已存在且非软链接，需手动处理）"
      continue
    fi

    ln -s "${rel_target}" "${link}"
  done
}

# ── 维护 .gitignore ───────────────────────────────────────
update_gitignore() {
  local gitignore="${TARGET_PROJECT}/.gitignore"
  local block_start="# devflow personal AI ignores — DO NOT EDIT MANUALLY"
  local block_end="# end devflow personal AI ignores"

  local block
  block="$(cat <<BLOCK
${block_start}
.claude/
.codex/
${block_end}
BLOCK
)"

  if [[ ! -f "${gitignore}" ]]; then
    printf '%s\n' "${block}" > "${gitignore}"
    ok ".gitignore 已创建并写入忽略规则"
    return
  fi

  # 已有 block 则替换，否则追加
  if grep -qF "${block_start}" "${gitignore}" 2>/dev/null; then
    # 用 Python 替换 block（兼容性更好）
    python3 - "${gitignore}" "${block_start}" "${block_end}" "${block}" <<'PYEOF'
import sys
path, start_marker, end_marker, new_block = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path, 'r') as f:
    content = f.read()
lines = content.split('\n')
out, inside = [], False
for line in lines:
    if line == start_marker:
        inside = True
        continue
    if inside:
        if line == end_marker:
            inside = False
        continue
    out.append(line)
# 追加新 block
result = '\n'.join(out).rstrip('\n') + '\n\n' + new_block + '\n'
with open(path, 'w') as f:
    f.write(result)
PYEOF
    ok ".gitignore 忽略规则已更新"
  else
    printf '\n%s\n' "${block}" >> "${gitignore}"
    ok ".gitignore 已追加忽略规则"
  fi
}

# ── 清理已被 Git 跟踪的个人 AI 配置 ───────────────────────
untrack_ai_configs() {
  cd "${TARGET_PROJECT}"

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return 0  # 非 Git 仓库，跳过
  fi

  local patterns=(".claude" ".codex")
  local cleaned=0

  for pattern in "${patterns[@]}"; do
    local tracked
    tracked="$(git ls-files --error-unmatch "${pattern}" 2>/dev/null || true)"
    if [[ -n "${tracked}" ]]; then
      git rm -r --cached --quiet "${pattern}" 2>/dev/null || true
      warn "${pattern} 已从 Git index 移除（本地文件保留）"
      cleaned=$((cleaned + 1))
    fi
  done

  [[ ${cleaned} -eq 0 ]] && ok "Git index 无需清理"
}

# ── 主流程 ────────────────────────────────────────────────
AI_SKILLS_DIR="${TARGET_PROJECT}/.ai/skills"
AI_AGENTS_DIR="${TARGET_PROJECT}/.ai/agents"

echo "── Skills ───────────────────────────────"
sync_entries "${SOURCE_SKILLS_DIR}" "${AI_SKILLS_DIR}" "skills"

echo "── Agents ───────────────────────────────"
sync_entries "${SOURCE_AGENTS_DIR}" "${AI_AGENTS_DIR}" "agents"

echo "── 软链接 ───────────────────────────────"
CLAUDE_SKILLS="${TARGET_PROJECT}/.claude/skills"
CODEX_SKILLS="${TARGET_PROJECT}/.codex/skills"
CLAUDE_AGENTS="${TARGET_PROJECT}/.claude/agents"
CODEX_AGENTS="${TARGET_PROJECT}/.codex/agents"

create_symlinks "${AI_SKILLS_DIR}" "${CLAUDE_SKILLS}" "skills"
ok ".claude/skills/ 链接已更新"

if [[ -d "${TARGET_PROJECT}/.codex" ]]; then
  create_symlinks "${AI_SKILLS_DIR}" "${CODEX_SKILLS}" "skills"
  ok ".codex/skills/ 链接已更新"
else
  warn ".codex/ 不存在，跳过 codex 链接"
fi

[[ -d "${AI_AGENTS_DIR}" ]] && {
  create_symlinks "${AI_AGENTS_DIR}" "${CLAUDE_AGENTS}" "agents"
  ok ".claude/agents/ 链接已更新"

  if [[ -d "${TARGET_PROJECT}/.codex" ]]; then
    create_symlinks "${AI_AGENTS_DIR}" "${CODEX_AGENTS}" "agents"
    ok ".codex/agents/ 链接已更新"
  fi
}

echo ""
echo "── .gitignore ───────────────────────────"
update_gitignore

echo ""
echo "── Git index ────────────────────────────"
untrack_ai_configs

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ 同步完成${RESET}"
echo ""
