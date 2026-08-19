#!/bin/bash
# DevFlow PreToolUse 状态守卫 hook
# 拦截非法状态写入，并在合法跃迁前写入 checkpoint
# 环境变量由 Claude Code 注入：TOOL_NAME, TOOL_INPUT

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# 只拦截写操作
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then exit 0; fi

# 检查 jq 是否可用
if ! command -v jq &>/dev/null; then
  echo "devflow-state-guard: jq not found, skipping" >&2
  exit 0
fi

# 未初始化时静默放行
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

WORK_ITEM=$(jq -r '.currentWorkItem // ""' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
if [[ -z "$WORK_ITEM" || "$WORK_ITEM" == "null" ]]; then exit 0; fi

META_FILE="$DEVFLOW_DIR/work-items/$WORK_ITEM/meta.json"
if [[ ! -f "$META_FILE" ]]; then exit 0; fi

STATUS=$(jq -r '.status // ""' "$META_FILE" 2>/dev/null)
WORK_ITEM_TYPE=$(jq -r '.type // ""' "$META_FILE" 2>/dev/null)

# 提取目标文件路径
TARGET=$(echo "${TOOL_INPUT:-{}}" | jq -r '.file_path // .path // ""' 2>/dev/null)

# 只检查 .devflow/work-items/ 下的文件
if ! echo "$TARGET" | grep -q "work-items/$WORK_ITEM/"; then exit 0; fi

# 取相对于工作项目录的路径
REL_PATH=$(echo "$TARGET" | sed "s|.*work-items/$WORK_ITEM/||")

# 允许写入前写 checkpoint
_write_checkpoint() {
  local CHECKPOINT_DIR="$DEVFLOW_DIR/work-items/$WORK_ITEM/checkpoints"
  mkdir -p "$CHECKPOINT_DIR"
  cp "$META_FILE" "$CHECKPOINT_DIR/meta-$(date -u +%Y%m%dT%H%M%SZ).json"
  # 只保留最近 10 份
  ls -t "$CHECKPOINT_DIR"/meta-*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
}

# Bug 类型跳过 spec 文件拦截（Bug 流程：created→coding→reviewing→done）
if [[ "$WORK_ITEM_TYPE" == "bug" ]]; then
  _write_checkpoint
  exit 0
fi

# 状态-文件映射（每个状态允许写入的文件模式）
case "$STATUS" in
  analyzing)  ALLOWED="spec/requirement.md|open-issues.md|progress.md" ;;
  designing)  ALLOWED="spec/design.md|spec/api.md|open-issues.md|progress.md" ;;
  planning)   ALLOWED="tasks.md|open-issues.md|progress.md" ;;
  coding)     ALLOWED="progress.md|tasks.md" ;;
  reviewing)  ALLOWED="review.md|tasks.md|open-issues.md|progress.md" ;;
  *)          exit 0 ;;
esac

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if ! echo "$REL_PATH" | grep -qE "^($ALLOWED)$"; then
  # 记录拦截事件（用 jq -n 避免注入）
  jq -n \
    --arg ts "$TS" \
    --arg tool "$TOOL_NAME" \
    --arg reason "状态拦截：$STATUS 不允许写入 $REL_PATH" \
    --arg workItem "$WORK_ITEM" \
    '{"ts":$ts,"tool":$tool,"blocked":true,"reason":$reason,"workItem":$workItem}' \
    >> "$AUDIT_LOG"

  echo "⛔ DevFlow 状态拦截：当前状态 [$STATUS] 不允许写入 $(basename "$TARGET")"
  echo "   合法写入目标：$ALLOWED"
  exit 1
fi

# 允许写入前写 checkpoint
_write_checkpoint
exit 0
