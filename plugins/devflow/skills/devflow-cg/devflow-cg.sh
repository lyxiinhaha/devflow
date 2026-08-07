#!/usr/bin/env bash
# devflow-cg — DevFlow CodeGraph 多根目录统一查询入口
#
# 用法：
#   devflow-cg explore "<query>"         # 符号/模块探查
#   devflow-cg impact <symbol>           # 爆炸半径分析
#   devflow-cg status                    # 索引新鲜度检查（仅输出警告，不重建）
#   devflow-cg sync                      # 同步所有本地 path Pod 的索引
#   devflow-cg index                     # 重建所有 root 的全量索引
#
# 返回：合并后的 JSON 或文本结果（多根时自动合并，调用方无需感知）
# Token 消耗：0（纯脚本执行，不走 LLM）

set -euo pipefail

# ── 颜色 ───────────────────────────────────────────────
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# ── 找 workspace.json ─────────────────────────────────
find_workspace() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/.devflow/workspace.json" ]] && { echo "$dir/.devflow/workspace.json"; return; }
    dir="$(dirname "$dir")"
  done
  echo ""
}

WORKSPACE_JSON="$(find_workspace)"

if [[ -z "$WORKSPACE_JSON" ]]; then
  echo "error: .devflow/workspace.json not found. Run 'devflow init' first." >&2
  exit 1
fi

PROJECT_ROOT="$(dirname "$(dirname "$WORKSPACE_JSON")")"

# ── 读 codegraph 配置 ────────────────────────────────
STRATEGY="$(python3 -c "
import json, sys
d = json.load(open('$WORKSPACE_JSON'))
print(d.get('codegraph', {}).get('strategy', 'single-root'))
" 2>/dev/null || echo "single-root")"

get_roots() {
  python3 -c "
import json
d = json.load(open('$WORKSPACE_JSON'))
roots = d.get('codegraph', {}).get('roots', [{'path': '.'}])
for r in roots:
  print(r['path'])
" 2>/dev/null || echo "."
}

# ── 索引新鲜度检查 ───────────────────────────────────
check_freshness() {
  local root_abs
  local warned=0

  while IFS= read -r root_path; do
    # 相对路径转绝对路径
    if [[ "$root_path" = /* ]]; then
      root_abs="$root_path"
    else
      root_abs="$PROJECT_ROOT/$root_path"
    fi

    local db="$root_abs/.codegraph/codegraph.db"
    [[ -f "$db" ]] || continue

    local db_mtime
    db_mtime="$(stat -f "%m" "$db" 2>/dev/null || stat -c "%Y" "$db" 2>/dev/null)"

    # iOS：检查 Podfile.lock
    local podlock="$root_abs/Podfile.lock"
    if [[ -f "$podlock" ]]; then
      local pod_mtime
      pod_mtime="$(stat -f "%m" "$podlock" 2>/dev/null || stat -c "%Y" "$podlock" 2>/dev/null)"
      if [[ "$pod_mtime" -gt "$db_mtime" ]]; then
        echo -e "${YELLOW}⚠️  ${root_abs}: Podfile.lock 比索引新，建议执行: devflow-cg index${RESET}" >&2
        warned=1
      fi
    fi

    # Android/KMP：检查 .gitmodules
    local gitmodules="$root_abs/.gitmodules"
    if [[ -f "$gitmodules" ]]; then
      # 检查各 submodule HEAD 是否比 db 新
      while IFS= read -r submod_path; do
        local head_file="$root_abs/$submod_path/.git/HEAD"
        [[ -f "$head_file" ]] || continue
        local head_mtime
        head_mtime="$(stat -f "%m" "$head_file" 2>/dev/null || stat -c "%Y" "$head_file" 2>/dev/null)"
        if [[ "$head_mtime" -gt "$db_mtime" ]]; then
          echo -e "${YELLOW}⚠️  submodule $(basename "$submod_path") 有更新，建议执行: devflow-cg index${RESET}" >&2
          warned=1
          break
        fi
      done < <(git -C "$root_abs" config --file .gitmodules --get-regexp 'path' 2>/dev/null | awk '{print $2}')
    fi
  done < <(get_roots)

  return $warned
}

# ── 路由：根据 symbol 找对应 root ────────────────────
route_root() {
  local symbol="$1"
  # 从 workspace.json moduleRootMap 查找
  python3 -c "
import json
d = json.load(open('$WORKSPACE_JSON'))
mapping = d.get('codegraph', {}).get('moduleRootMap', {})
symbol = '''$symbol'''
# 精确匹配 or 前缀匹配
for mod, path in mapping.items():
  if mod.lower() in symbol.lower():
    print(path)
    exit(0)
print('.')  # 默认壳工程 root
" 2>/dev/null || echo "."
}

abs_root() {
  local p="$1"
  if [[ "$p" = /* ]]; then echo "$p"
  else echo "$PROJECT_ROOT/$p"; fi
}

# ── 主命令处理 ────────────────────────────────────────
CMD="${1:-}"
shift || true

case "$CMD" in

  explore)
    QUERY="${*:-}"
    if [[ -z "$QUERY" ]]; then
      echo "usage: devflow-cg explore <query>" >&2; exit 1
    fi

    if [[ "$STRATEGY" == "single-root" ]]; then
      # 单根：直接执行，零路由开销
      cd "$PROJECT_ROOT" && codegraph explore "$QUERY"
    else
      # 多根：定向查询 + 壳工程全局查，合并输出
      COMPONENT_ROOT="$(route_root "$QUERY")"
      SHELL_ROOT="."

      echo "━━ [component: $COMPONENT_ROOT] ━━"
      cd "$(abs_root "$COMPONENT_ROOT")" && codegraph explore "$QUERY" || true

      if [[ "$COMPONENT_ROOT" != "$SHELL_ROOT" ]]; then
        echo ""
        echo "━━ [shell: $PROJECT_ROOT (global callers)] ━━"
        cd "$PROJECT_ROOT" && codegraph explore "$QUERY" || true
      fi
    fi
    ;;

  impact)
    SYMBOL="${*:-}"
    if [[ -z "$SYMBOL" ]]; then
      echo "usage: devflow-cg impact <symbol>" >&2; exit 1
    fi

    if [[ "$STRATEGY" == "single-root" ]]; then
      cd "$PROJECT_ROOT" && codegraph impact "$SYMBOL"
    else
      # 爆炸半径必须在壳工程 root 执行才能获取完整全局调用方
      COMPONENT_ROOT="$(route_root "$SYMBOL")"

      if [[ "$COMPONENT_ROOT" != "." ]]; then
        echo "━━ [component impact: $COMPONENT_ROOT] ━━"
        cd "$(abs_root "$COMPONENT_ROOT")" && codegraph impact "$SYMBOL" || true
        echo ""
        echo "━━ [global impact from shell root] ━━"
      fi

      cd "$PROJECT_ROOT" && codegraph impact "$SYMBOL"
    fi
    ;;

  status)
    echo "CodeGraph 索引新鲜度检查..."
    check_freshness && echo -e "${GREEN}✓ 所有索引均为最新${RESET}" || true
    ;;

  sync)
    # 同步所有本地 path Pod（mtime 比 db 新的才 sync）
    while IFS= read -r root_path; do
      root_abs="$(abs_root "$root_path")"
      db="$root_abs/.codegraph/codegraph.db"
      [[ -f "$db" ]] || continue

      db_mtime="$(stat -f "%m" "$db" 2>/dev/null || stat -c "%Y" "$db" 2>/dev/null)"
      has_change=0

      # 检查该 root 下是否有比 db 新的源码文件
      if find "$root_abs/src" "$root_abs/lib" "$root_abs/Sources" \
           -name "*.kt" -o -name "*.swift" -o -name "*.java" \
           2>/dev/null | xargs stat -f "%m" 2>/dev/null | \
           awk -v t="$db_mtime" '{if ($1 > t) exit 1}'; then
        :
      else
        has_change=1
      fi

      if [[ $has_change -eq 1 ]]; then
        echo "syncing $root_abs ..."
        cd "$root_abs" && codegraph sync -q
        echo -e "${GREEN}✓ synced: $root_abs${RESET}"
      else
        echo "skip (up to date): $root_abs"
      fi
    done < <(get_roots)
    ;;

  index)
    # 重建所有 root 的全量索引
    while IFS= read -r root_path; do
      root_abs="$(abs_root "$root_path")"
      echo "rebuilding index: $root_abs ..."
      cd "$root_abs" && codegraph index
      echo -e "${GREEN}✓ rebuilt: $root_abs${RESET}"
    done < <(get_roots)

    # 更新 workspace.json 的 lastRebuildAt
    python3 -c "
import json, datetime
path = '$WORKSPACE_JSON'
d = json.load(open(path))
d.setdefault('codegraph', {})['lastRebuildAt'] = datetime.datetime.utcnow().isoformat() + 'Z'
json.dump(d, open(path, 'w'), indent=2, ensure_ascii=False)
print('updated lastRebuildAt in workspace.json')
" 2>/dev/null || true
    ;;

  *)
    echo "DevFlow CodeGraph 多根目录查询工具"
    echo ""
    echo "用法："
    echo "  devflow-cg explore \"<query>\"    符号/模块探查（自动路由 + 合并）"
    echo "  devflow-cg impact <symbol>       爆炸半径分析（自动路由 + 合并）"
    echo "  devflow-cg status                索引新鲜度检查"
    echo "  devflow-cg sync                  同步有变更的本地 Pod 索引"
    echo "  devflow-cg index                 重建所有 root 全量索引"
    echo ""
    echo "策略：$STRATEGY"
    echo "Project root：$PROJECT_ROOT"
    ;;
esac
