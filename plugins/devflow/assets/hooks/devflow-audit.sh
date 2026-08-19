#!/bin/bash
# DevFlow PostToolUse 审计 hook
# 由 Claude Code 宿主在每次工具调用后执行，独立于 AI 上下文
# 环境变量由 Claude Code 注入：TOOL_NAME, TOOL_INPUT

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# jq 不存在时静默跳过（避免无意义的报错）
if ! command -v jq &>/dev/null; then
  echo "devflow-audit: jq not found, skipping" >&2
  exit 0
fi

# 未初始化时静默跳过
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

WORK_ITEM=$(jq -r '.currentWorkItem // "none"' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# TOOL_INPUT 可能为空，兜底为 {}
# bash 参数展开默认值中不能含未转义的 }，故拆为两步
INPUT="${TOOL_INPUT}"
[[ -z "$INPUT" ]] && INPUT="{}"

# 使用 jq -n 构造 JSON，避免 TOOL_NAME/WORK_ITEM 含特殊字符时的注入风险
jq -n --arg ts "$TS" --arg tool "$TOOL_NAME" \
      --arg workItem "$WORK_ITEM" --argjson input "$INPUT" \
      '{"ts":$ts,"tool":$tool,"workItem":$workItem,"input":$input}' \
  >> "$AUDIT_LOG"
