#!/bin/bash
# DevFlow PostToolUse 审计 hook
# Claude Code 通过 stdin 传入 JSON，格式：{"tool_name":"...","tool_input":{...},"tool_response":{},"session_id":"..."}

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# jq 不存在时静默跳过
if ! command -v jq &>/dev/null; then
  echo "devflow-audit: jq not found, skipping" >&2
  exit 0
fi

# 未初始化时静默跳过
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

# 从 stdin 读取 JSON（Claude Code hooks 规范）
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT_VAL=$(echo "$INPUT" | jq -c '.tool_input // {}')

WORK_ITEM=$(jq -r '.currentWorkItem // "none"' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n \
  --arg ts "$TS" \
  --arg tool "$TOOL_NAME" \
  --arg workItem "$WORK_ITEM" \
  --argjson input "$TOOL_INPUT_VAL" \
  '{"ts":$ts,"tool":$tool,"workItem":$workItem,"input":$input}' \
  >> "$AUDIT_LOG"
