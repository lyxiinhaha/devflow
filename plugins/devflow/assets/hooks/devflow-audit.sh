#!/bin/bash
# DevFlow PostToolUse 审计 hook
# 由 Claude Code 宿主在每次工具调用后执行，独立于 AI 上下文
# 环境变量由 Claude Code 注入：TOOL_NAME, TOOL_INPUT

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# 未初始化时静默跳过
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

WORK_ITEM=$(jq -r '.currentWorkItem // "none"' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# TOOL_INPUT 可能为空，兜底为 {}
# 注意：不能用 ${TOOL_INPUT:-{}}，bash 不跟踪默认值内的 {} 嵌套，会在结果末尾多出一个 }
INPUT="${TOOL_INPUT}"
[[ -z "$INPUT" ]] && INPUT="{}"

echo "{\"ts\":\"$TS\",\"tool\":\"$TOOL_NAME\",\"workItem\":\"$WORK_ITEM\",\"input\":$INPUT}" \
  >> "$AUDIT_LOG"
