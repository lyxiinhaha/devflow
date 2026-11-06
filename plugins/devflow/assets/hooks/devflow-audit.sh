#!/bin/bash
# DevFlow PostToolUse 审计 hook
# Claude Code 与 Kiro CLI V3 均通过 stdin 传入 Hook 事件 JSON。

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# jq 不存在时静默跳过
if ! command -v jq &>/dev/null; then
  echo "devflow-audit: jq not found, skipping" >&2
  exit 0
fi

# 未初始化时静默跳过
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

# Skip malformed events and avoid persisting tool inputs, which may contain secrets.
INPUT=$(cat)
if ! printf '%s' "$INPUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "devflow-audit: invalid event JSON, skipping" >&2
  exit 0
fi
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')

WORK_ITEM=$(jq -r '.focus // .currentWorkItem // "none"' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -nc \
  --arg ts "$TS" \
  --arg tool "$TOOL_NAME" \
  --arg workItem "$WORK_ITEM" \
  '{"ts":$ts,"tool":$tool,"workItem":$workItem}' \
  >> "$AUDIT_LOG"
