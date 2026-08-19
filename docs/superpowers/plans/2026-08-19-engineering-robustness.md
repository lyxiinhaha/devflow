# DevFlow 工程化鲁棒性 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 DevFlow 添加独立 hook 审计层、显式状态机强约束、断点 checkpoint 回滚，将工程化鲁棒性从"AI 自述"提升到"独立机械记录 + AI 语义补充"双层架构。

**Architecture:** Hook 脚本（PostToolUse/PreToolUse）由 Claude Code 宿主独立执行，记录工具调用行为并拦截非法状态写入；progress.md 结构化日志由 AI 追加，记录决策语义。两层互补，非 Claude Code 平台自动降级为仅 progress.md 语义层。

**Tech Stack:** Bash shell scripts, Markdown (AI instruction files), JSON (meta.json / workspace.json / audit-log.jsonl)

**规格文档：** `docs/superpowers/specs/2026-08-19-engineering-robustness-design.md`

---

## 文件结构

| 路径 | 操作 | 职责 |
|------|------|------|
| `plugins/devflow/assets/templates/progress.tpl.md` | 修改 | 工作项进度日志模板，新增结构化文件头和条目格式说明 |
| `plugins/devflow/assets/hooks/devflow-audit.sh` | 新建 | PostToolUse hook，独立追加 audit-log.jsonl |
| `plugins/devflow/assets/hooks/devflow-state-guard.sh` | 新建 | PreToolUse hook，拦截非法状态写入 + 写 checkpoint |
| `plugins/devflow/commands/audit.md` | 新建 | devflow audit 子命令，查询审计日志摘要 |
| `plugins/devflow/commands/init.md` | 修改 | 新增步骤 6.5：安装 hook 脚本到项目 .devflow/hooks/ |
| `plugins/devflow/commands/continue.md` | 修改 | 增强步骤 4：读取 progress.md 最后 25 条，检测中断状态 |
| `plugins/devflow/commands/analyze.md` | 修改 | 新增「状态验证」扩展和「执行日志规范」区块 |
| `plugins/devflow/commands/design.md` | 修改 | 同上，扩展已有状态检查格式 |
| `plugins/devflow/commands/estimate.md` | 修改 | 同上 |
| `plugins/devflow/commands/plan.md` | 修改 | 同上 |
| `plugins/devflow/commands/code.md` | 修改 | 同上 |
| `plugins/devflow/commands/review.md` | 修改 | 同上 |
| `plugins/devflow/commands/retrospect.md` | 修改 | 同上 |
| `plugins/devflow/commands/fix.md` | 修改 | 同上，注明 Bug 类型跳过 spec 文件拦截 |

---

## Task 1：更新 progress.tpl.md 模板

**Files:**
- Modify: `plugins/devflow/assets/templates/progress.tpl.md`

- [ ] **Step 1：将文件内容替换为新版结构化模板**

```markdown
# 进度记录：{title}

> **工作项 ID**：{id}  **Meegle**：{linkedMeegleId | 未关联}
> 此文件由 DevFlow 自动维护，请勿手动编辑日志条目。

<!-- STATE_MACHINE: created→analyzing→designing→estimating→planning→coding→reviewing→done -->

## Context Checkpoint（关键约束摘要）

<!-- 每个阶段完成时自动更新，用于新会话快速恢复上下文 -->

| 阶段 | 时间 | 关键决策 / 约束 |
|------|------|----------------|
|      |      |                |

## 执行日志

<!-- 条目格式（严格追加，禁止修改已有内容）：
[START]      {timestamp} devflow {command}
[READ]       {filepath}
[WRITE]      {filepath} ({新建|修改})
[DECISION]   {决策内容} — 原因：{原因}
[TRANSITION] {from} → {to} ({command}, 前驱合法)
[ERROR]      {原因}，命令中止
[COMPLETE]   devflow {command} — {timestamp}
-->
```

- [ ] **Step 2：验证模板文件内容正确**

```bash
grep -c "STATE_MACHINE" plugins/devflow/assets/templates/progress.tpl.md
grep -c "DECISION" plugins/devflow/assets/templates/progress.tpl.md
```

期望输出：两条均返回 `1`

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/assets/templates/progress.tpl.md
git commit -m "feat(robustness): 更新 progress.tpl.md 为结构化审计日志格式"
```

---

## Task 2：创建 devflow-audit.sh（PostToolUse hook）

**Files:**
- Create: `plugins/devflow/assets/hooks/devflow-audit.sh`

- [ ] **Step 1：创建目录并写入脚本**

```bash
mkdir -p plugins/devflow/assets/hooks
```

文件内容（完整写入 `plugins/devflow/assets/hooks/devflow-audit.sh`）：

```bash
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
INPUT="${TOOL_INPUT:-{}}"

echo "{\"ts\":\"$TS\",\"tool\":\"$TOOL_NAME\",\"workItem\":\"$WORK_ITEM\",\"input\":$INPUT}" \
  >> "$AUDIT_LOG"
```

- [ ] **Step 2：赋予执行权限**

```bash
chmod +x plugins/devflow/assets/hooks/devflow-audit.sh
```

- [ ] **Step 3：用测试输入验证脚本可执行（不依赖真实 .devflow）**

```bash
# 临时构造一个最小 .devflow 环境测试
mkdir -p /tmp/devflow-test/.devflow
echo '{"currentWorkItem":"test-item"}' > /tmp/devflow-test/.devflow/workspace.json

cd /tmp/devflow-test
TOOL_NAME="Write" TOOL_INPUT='{"file_path":"spec/design.md"}' \
  bash /Users/apple/work/workflow/devflow/plugins/devflow/assets/hooks/devflow-audit.sh

cat .devflow/audit-log.jsonl
cd -
rm -rf /tmp/devflow-test
```

期望输出（示例）：
```
{"ts":"2026-08-19T...","tool":"Write","workItem":"test-item","input":{"file_path":"spec/design.md"}}
```

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/assets/hooks/devflow-audit.sh
git commit -m "feat(robustness): 新增 PostToolUse 审计 hook devflow-audit.sh"
```

---

## Task 3：创建 devflow-state-guard.sh（PreToolUse hook）

**Files:**
- Create: `plugins/devflow/assets/hooks/devflow-state-guard.sh`

- [ ] **Step 1：写入脚本**

文件内容（完整写入 `plugins/devflow/assets/hooks/devflow-state-guard.sh`）：

```bash
#!/bin/bash
# DevFlow PreToolUse 状态守卫 hook
# 拦截非法状态写入，并在合法跃迁前写入 checkpoint
# 环境变量由 Claude Code 注入：TOOL_NAME, TOOL_INPUT

DEVFLOW_DIR=".devflow"
AUDIT_LOG="$DEVFLOW_DIR/audit-log.jsonl"

# 只拦截写操作
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then exit 0; fi

# 未初始化时静默放行
if [[ ! -f "$DEVFLOW_DIR/workspace.json" ]]; then exit 0; fi

WORK_ITEM=$(jq -r '.currentWorkItem // ""' "$DEVFLOW_DIR/workspace.json" 2>/dev/null)
if [[ -z "$WORK_ITEM" || "$WORK_ITEM" == "null" ]]; then exit 0; fi

META_FILE="$DEVFLOW_DIR/work-items/$WORK_ITEM/meta.json"
if [[ ! -f "$META_FILE" ]]; then exit 0; fi

STATUS=$(jq -r '.status // ""' "$META_FILE" 2>/dev/null)
WORK_ITEM_TYPE=$(jq -r '.type // ""' "$META_FILE" 2>/dev/null)

# Bug 类型跳过 spec 文件拦截（Bug 流程：created→coding→reviewing→done）
if [[ "$WORK_ITEM_TYPE" == "bug" ]]; then
  _do_checkpoint "$STATUS"
  exit 0
fi

# 提取目标文件路径
TARGET=$(echo "${TOOL_INPUT:-{}}" | jq -r '.file_path // .path // ""' 2>/dev/null)
# 只检查 .devflow/work-items/ 下的文件
if ! echo "$TARGET" | grep -q "work-items/$WORK_ITEM/"; then exit 0; fi
# 取相对于工作项目录的路径
REL_PATH=$(echo "$TARGET" | sed "s|.*work-items/$WORK_ITEM/||")

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
  # 记录拦截事件
  echo "{\"ts\":\"$TS\",\"tool\":\"$TOOL_NAME\",\"blocked\":true,\"reason\":\"状态拦截：$STATUS 不允许写入 $REL_PATH\",\"workItem\":\"$WORK_ITEM\"}" \
    >> "$AUDIT_LOG"

  echo "⛔ DevFlow 状态拦截：当前状态 [$STATUS] 不允许写入 $(basename "$TARGET")"
  echo "   合法写入目标：$ALLOWED"
  exit 1
fi

# 允许写入前写 checkpoint
CHECKPOINT_DIR="$DEVFLOW_DIR/work-items/$WORK_ITEM/checkpoints"
mkdir -p "$CHECKPOINT_DIR"
cp "$META_FILE" "$CHECKPOINT_DIR/meta-$(date -u +%Y%m%dT%H%M%SZ).json"

# 只保留最近 10 份
ls -t "$CHECKPOINT_DIR"/meta-*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null

exit 0
```

- [ ] **Step 2：赋予执行权限**

```bash
chmod +x plugins/devflow/assets/hooks/devflow-state-guard.sh
```

- [ ] **Step 3：测试合法写入（应放行并生成 checkpoint）**

```bash
mkdir -p /tmp/sg-test/.devflow/work-items/20260819-Test/checkpoints
cat > /tmp/sg-test/.devflow/workspace.json << 'EOF'
{"currentWorkItem":"20260819-Test"}
EOF
cat > /tmp/sg-test/.devflow/work-items/20260819-Test/meta.json << 'EOF'
{"status":"analyzing","type":"feature"}
EOF

cd /tmp/sg-test
TOOL_NAME="Write" \
  TOOL_INPUT='{"file_path":".devflow/work-items/20260819-Test/spec/requirement.md"}' \
  bash /Users/apple/work/workflow/devflow/plugins/devflow/assets/hooks/devflow-state-guard.sh
echo "Exit code: $?"
ls .devflow/work-items/20260819-Test/checkpoints/
cd -
rm -rf /tmp/sg-test
```

期望：退出码 `0`，checkpoints/ 目录下生成一个 `meta-*.json` 文件

- [ ] **Step 4：测试非法写入（应拦截并输出错误）**

```bash
mkdir -p /tmp/sg-test2/.devflow/work-items/20260819-Test/checkpoints
cat > /tmp/sg-test2/.devflow/workspace.json << 'EOF'
{"currentWorkItem":"20260819-Test"}
EOF
cat > /tmp/sg-test2/.devflow/work-items/20260819-Test/meta.json << 'EOF'
{"status":"analyzing","type":"feature"}
EOF

cd /tmp/sg-test2
TOOL_NAME="Write" \
  TOOL_INPUT='{"file_path":".devflow/work-items/20260819-Test/spec/design.md"}' \
  bash /Users/apple/work/workflow/devflow/plugins/devflow/assets/hooks/devflow-state-guard.sh
echo "Exit code: $?"
cd -
rm -rf /tmp/sg-test2
```

期望：退出码 `1`，终端输出含 `⛔ DevFlow 状态拦截：当前状态 [analyzing] 不允许写入 design.md`

- [ ] **Step 5：提交**

```bash
git add plugins/devflow/assets/hooks/devflow-state-guard.sh
git commit -m "feat(robustness): 新增 PreToolUse 状态守卫 hook devflow-state-guard.sh"
```

---

## Task 4：创建 commands/audit.md

**Files:**
- Create: `plugins/devflow/commands/audit.md`

- [ ] **Step 1：写入文件**

完整内容（写入 `plugins/devflow/commands/audit.md`）：

```markdown
---
name: devflow-audit
description: DevFlow 审计日志查询。合并展示 audit-log.jsonl（hook 独立记录）和 progress.md [DECISION] 条目，输出阶段轨迹、文件操作统计、关键决策和被拦截操作。当用户说「审计日志」「查看操作记录」「devflow audit」或需要追溯 AI 操作历史时触发。
---

# devflow audit — 审计日志查询

**用途：** 合并两个数据源（hook 独立审计 + AI 决策自述）输出可读的操作摘要，支持按工作项、时间范围、事件类型过滤。

---

## 前置条件

- `.devflow/` 目录存在。
- `workspace.json` 可读。

---

## 调用方式

通过 `$ARGUMENTS` 传入参数，支持以下模式：

```
devflow audit                    # 当前工作项摘要（默认）
devflow audit --tail 25          # 最近 25 条原始条目
devflow audit --blocked          # 仅展示被拦截的操作
devflow audit --decisions        # 仅展示 AI 决策条目（来自 progress.md）
devflow audit {workItemId}       # 指定工作项摘要
```

---

## 执行步骤

### 1. 确定目标工作项

- 未传入 workItemId：读取 `workspace.json.currentWorkItem`
- 传入 workItemId：直接使用

工作项不存在时输出：
```
✗ 工作项 {id} 不存在，请检查 ID 是否正确。
```

### 2. 读取数据源

**来源 A：** `.devflow/audit-log.jsonl`（hook 写入，每行一条 JSON）

若文件不存在或为空，说明当前平台不支持 hook（Cursor / Codex / OpenCode 等），输出：
```
⚠️  当前平台为软约束模式，audit-log.jsonl 为空。
    仅展示 progress.md 中的 AI 决策记录。
```

**来源 B：** `.devflow/work-items/{workItemId}/progress.md`

提取所有以 `[DECISION]` 或 `[TRANSITION]` 或 `[ERROR]` 开头的行。

### 3. 合并并展示

按时间戳升序合并两个来源。

#### 默认摘要输出格式

```
DevFlow Audit — {workItemId}
─────────────────────────────────────────────────
阶段轨迹：
  {✅|⚠️} {from} → {to}   {timestamp}  {（异常中断，未完成）如有}

文件操作：{n} 次读取，{n} 次写入，{n} 次拦截

关键决策：
  [{HH:MM}] {DECISION 内容}

被拦截操作：（无则省略本节）
  [{HH:MM}] ⛔ {tool} {target} 被拦截 — {原因}

运行 `devflow audit --tail 25` 查看原始条目
```

**阶段判断逻辑：**
- 若某状态有对应的 `[TRANSITION]` 条目且后续存在 `[COMPLETE]` → ✅
- 若某状态有 `[TRANSITION]` 但后续无 `[COMPLETE]`，或末尾条目为 `[ERROR]` → ⚠️（异常中断）

#### `--tail 25` 原始输出格式

读取 audit-log.jsonl 最后 25 行 + progress.md 最后 25 个结构化条目，合并后按时间戳排序展示：

```
{timestamp}  [{EVENT_TYPE}]  {内容}
```

#### `--blocked` 输出

仅展示 audit-log.jsonl 中 `blocked: true` 的条目：

```
被拦截操作列表（共 {n} 次）：
{timestamp}  ⛔ {tool} {target} — {reason}
```

#### `--decisions` 输出

仅展示 progress.md 中 `[DECISION]` 条目：

```
AI 决策记录（共 {n} 条）：
{timestamp}  {DECISION 内容}
```

---

## 软约束模式降级

audit-log.jsonl 为空（非 Claude Code 平台）时：
- 阶段轨迹从 progress.md `[TRANSITION]` 条目提取
- 文件操作统计从 progress.md `[READ]` / `[WRITE]` 条目提取
- 被拦截操作节省略（无独立记录）
- 在摘要底部注明「数据来源：progress.md（软约束模式）」
```

- [ ] **Step 2：验证文件存在且格式正确**

```bash
head -5 plugins/devflow/commands/audit.md
grep -c "devflow-audit" plugins/devflow/commands/audit.md
```

期望：第一行为 `---`，第二条命令返回 `1`

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/audit.md
git commit -m "feat(robustness): 新增 devflow audit 子命令"
```

---

## Task 5：更新 commands/init.md — 新增 hook 安装步骤

**Files:**
- Modify: `plugins/devflow/commands/init.md`

- [ ] **Step 1：在步骤 6「建立 `.devflow/` 目录结构」之后，步骤 7「写入 `.gitignore`」之前，插入步骤 6.5**

在 `### 7. 写入 \`.gitignore\`` 标题**前**插入以下内容：

```markdown
### 6.5 安装 Hook（仅 Claude Code 平台）

检测当前平台（读取 `workspace.json.platform` 或通过 `$CLAUDE_CODE` 环境变量判断）：

**Claude Code 平台：**

1. 从插件包 `assets/hooks/` 复制 hook 脚本到 `.devflow/hooks/`：
   ```bash
   mkdir -p .devflow/hooks
   cp {插件根目录}/assets/hooks/devflow-audit.sh .devflow/hooks/
   cp {插件根目录}/assets/hooks/devflow-state-guard.sh .devflow/hooks/
   chmod +x .devflow/hooks/devflow-audit.sh
   chmod +x .devflow/hooks/devflow-state-guard.sh
   ```

2. 检查 `.claude/settings.json` 是否存在，追加 hooks 配置（不覆盖已有内容）：
   ```json
   {
     "hooks": {
       "PostToolUse": [".devflow/hooks/devflow-audit.sh"],
       "PreToolUse":  [".devflow/hooks/devflow-state-guard.sh"]
     }
   }
   ```
   若 `.claude/settings.json` 已存在 `hooks` 字段，则合并（不替换现有 hook），而非覆盖整个文件。
   若 `.claude/` 目录不存在，先 `mkdir -p .claude/` 再写入。

3. 确保 `.devflow/hooks/` 已加入 `.gitignore`（hook 脚本属于本地安装产物）。

4. 在 `devflow-profile.md` 的「约束模式」节写入：`硬约束模式（Claude Code + hook 已安装）`

**非 Claude Code 平台（Cursor / Codex / Gemini / OpenCode 等）：**

跳过 hook 安装，在 `devflow-profile.md` 的「约束模式」节写入：
```
软约束模式（当前平台不支持 hook，状态校验依赖 AI 自述）
devflow audit 仍可用，但 audit-log.jsonl 为空，仅展示 progress.md 决策记录。
```

```

- [ ] **Step 2：验证插入点正确**

```bash
grep -n "6.5 安装 Hook" plugins/devflow/commands/init.md
grep -n "7. 写入" plugins/devflow/commands/init.md
```

期望：步骤 6.5 的行号小于步骤 7 的行号

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/init.md
git commit -m "feat(robustness): init 新增 hook 安装步骤 6.5"
```

---

## Task 6：更新 commands/continue.md — 增强恢复逻辑

**Files:**
- Modify: `plugins/devflow/commands/continue.md`

- [ ] **Step 1：替换步骤 4「读取 Context Checkpoint」为新版恢复检测逻辑**

将 `### 4. 读取 Context Checkpoint（核心）` 整节（从该标题到下一个 `###` 标题前）替换为：

```markdown
### 4. 读取 Context Checkpoint 与中断检测（核心）

**4a. 中断检测（优先执行）**

读取 `progress.md` **最后 25 条**结构化日志条目（不读全文，控制 Token）。

检查末尾条目类型：
- 末尾为 `[COMPLETE]` → 正常结束，继续步骤 4b
- 末尾为 `[ERROR]` 或其他非 `[COMPLETE]` 条目 → **进入恢复模式**

**恢复模式流程：**

1. 读取 `.devflow/work-items/{id}/checkpoints/` 下最新的 `meta-*.json` 快照
2. 与当前 `meta.json` 对比状态字段
3. 展示中断现场摘要：

```
⚠️  检测到异常中断

  工作项：{title}
  中断位置：{最后一条 [START] 对应的命令}（{时间戳}）
  最后操作：{最后一条非 [START]/[COMPLETE] 条目}
  当前状态：{meta.json.status}
  上一稳定快照：{checkpoint 的 status}（{快照时间戳}）

  可选操作：
  1. 继续完成 devflow {command}（从当前状态恢复）
  2. 回滚到 {checkpoint status} 状态重新执行
  3. 查看完整中断日志（devflow audit --tail 25）

  选择 [1/2/3]：
```

选择 2 时：将 checkpoint 的 `meta-*.json` 内容覆写到 `meta.json`，告知用户状态已回滚。
选择 3 时：触发 `devflow audit --tail 25` 展示原始条目后重新询问 1/2。

`progress.md` 不存在或最后 25 条为空（新会话首次恢复）→ 跳过中断检测，直接进入步骤 4b。

**4b. 读取关键约束（Context Checkpoint 表格）**

检测无中断（或用户选择继续）后，读取 `progress.md` 中的 Context Checkpoint 表格，快速恢复关键约束，避免重读所有长文档浪费 Token。

再补充读取 `meta.json` 获取状态和各阶段完成情况。
```

- [ ] **Step 2：验证替换后的内容存在关键字**

```bash
grep -n "最后 25 条" plugins/devflow/commands/continue.md
grep -n "恢复模式" plugins/devflow/commands/continue.md
grep -n "checkpoint" plugins/devflow/commands/continue.md
```

期望：三条命令均有输出

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/continue.md
git commit -m "feat(robustness): continue 增强中断检测和 checkpoint 回滚能力"
```

---

## Task 7：标准化 commands/analyze.md

**Files:**
- Modify: `plugins/devflow/commands/analyze.md`

- [ ] **Step 1：在文件末尾「## 输出（Finalize 完成后）」节之后追加以下两个区块**

```markdown
---

## 状态验证（前置条件扩展）

执行 Finalize 模式前，读取 `meta.json.status`，合法前驱状态为：`created`。

非法时输出并中止：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow analyze。
  合法前驱状态：created
  如需重新分析需求，请执行 devflow change。
```

---

## 执行日志规范（progress.md 追加）

Finalize 模式执行期间，按以下规范追加日志条目，不得覆盖已有内容：

```
[START]      {ISO时间戳} devflow analyze
[READ]       context/sanitized.md
[READ]       {每个读取的 Figma/接口/CodeGraph 来源}
[DECISION]   {歧义分类决策摘要，如：歧义 3 条，2 条 ControlledPass，1 条 HardBlocker 阻断} — 原因：{简述}
[WRITE]      spec/requirement.md ({新建|修改})
[WRITE]      open-issues.md ({新建|修改})（若有 open issue 写入）
[TRANSITION] created → analyzing (devflow analyze, 前驱合法)
[COMPLETE]   devflow analyze — {ISO时间戳}
```

异常退出时追加：
```
[ERROR]      {原因}，命令中止
```
```

- [ ] **Step 2：验证**

```bash
grep -n "状态验证" plugins/devflow/commands/analyze.md
grep -n "执行日志规范" plugins/devflow/commands/analyze.md
```

期望：两条命令均有输出

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/analyze.md
git commit -m "feat(robustness): analyze 新增状态验证和执行日志规范区块"
```

---

## Task 8：标准化 commands/design.md

**Files:**
- Modify: `plugins/devflow/commands/design.md`

- [ ] **Step 1：在文件末尾追加两个标准区块**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`analyzing`（已在前置条件中说明）。

非法时统一错误格式：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow design。
  合法前驱状态：analyzing
  如需修改需求，请执行 devflow change。
```

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow design
[READ]       spec/requirement.md
[READ]       context/sanitized.md
[DECISION]   {技术方案选择，如：选方案 A，原因：...}
[DECISION]   {爆炸半径评估，如：影响 N 个调用方，风险等级 MEDIUM}
[WRITE]      spec/design.md ({新建|修改})
[WRITE]      spec/api.md ({新建|修改})（若有接口设计）
[TRANSITION] analyzing → designing (devflow design, 前驱合法)
[COMPLETE]   devflow design — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 2：验证**

```bash
grep -c "执行日志规范" plugins/devflow/commands/design.md
```

期望：`1`

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/design.md
git commit -m "feat(robustness): design 新增状态验证和执行日志规范区块"
```

---

## Task 9：标准化 commands/estimate.md、plan.md、code.md

**Files:**
- Modify: `plugins/devflow/commands/estimate.md`
- Modify: `plugins/devflow/commands/plan.md`
- Modify: `plugins/devflow/commands/code.md`

- [ ] **Step 1：在 estimate.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`designing`。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow estimate。
  合法前驱状态：designing
```

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow estimate
[READ]       spec/design.md
[DECISION]   {工作量估算结论，如：总计 5 个工作日，高风险任务 2 个}
[WRITE]      spec/estimate.md ({新建|修改})
[TRANSITION] designing → estimating (devflow estimate, 前驱合法)
[COMPLETE]   devflow estimate — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 2：在 plan.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`designing` 或 `estimating`（estimate 可跳过）。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow plan。
  合法前驱状态：designing / estimating
```

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow plan
[READ]       spec/design.md
[READ]       spec/requirement.md
[DECISION]   {切片模式选择，如：启用切片模式，共 3 个切片} — 原因：任务数 {n} ≥ 8
[DECISION]   {Bug 经验召回结果，如：召回 KB-003 KB-007，注入 T004 T009}
[WRITE]      tasks.md ({新建|修改})
[TRANSITION] {designing|estimating} → planning (devflow plan, 前驱合法)
[COMPLETE]   devflow plan — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 3：在 code.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`planning`（已在前置条件中说明）。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow code。
  合法前驱状态：planning
```

---

## 执行日志规范（progress.md 追加）

每个任务编码时追加，不要等全部完成后一次性写入：
```
[START]      {ISO时间戳} devflow code（任务：{任务ID} {任务名}）
[READ]       {修改的现有文件路径}（改动前必读原逻辑）
[DECISION]   {实现决策，如：选择复用现有 XxxUtil 而非新建，原因：...}
[WRITE]      {修改的文件路径} ({新建|修改})
[COMPLETE]   devflow code 任务 {任务ID} — {ISO时间戳}
```

全部任务完成后追加：
```
[TRANSITION] planning → coding (devflow code, 前驱合法)
[COMPLETE]   devflow code（全部任务）— {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 4：验证三个文件都有日志规范区块**

```bash
grep -l "执行日志规范" plugins/devflow/commands/estimate.md \
  plugins/devflow/commands/plan.md plugins/devflow/commands/code.md | wc -l
```

期望：`3`

- [ ] **Step 5：提交**

```bash
git add plugins/devflow/commands/estimate.md \
        plugins/devflow/commands/plan.md \
        plugins/devflow/commands/code.md
git commit -m "feat(robustness): estimate/plan/code 新增状态验证和执行日志规范区块"
```

---

## Task 10：标准化 commands/review.md、retrospect.md、fix.md

**Files:**
- Modify: `plugins/devflow/commands/review.md`
- Modify: `plugins/devflow/commands/retrospect.md`
- Modify: `plugins/devflow/commands/fix.md`

- [ ] **Step 1：在 review.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`coding`。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow review。
  合法前驱状态：coding
```

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow review
[READ]       tasks.md
[READ]       {审查的主要代码文件路径}
[DECISION]   {审查结论，如：发现 2 处 CRITICAL 问题，1 处 HIGH，已阻断合并}
[DECISION]   {回归义务判断，如：变更影响 PaymentModule，需补充回归测试}
[WRITE]      review.md ({新建|修改})
[TRANSITION] coding → reviewing (devflow review, 前驱合法)
[COMPLETE]   devflow review — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 2：在 retrospect.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`reviewing`。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow retrospect。
  合法前驱状态：reviewing
```

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow retrospect
[READ]       context/sanitized.md
[READ]       review.md
[DECISION]   {经验卡核心内容，如：根因为 XX 反模式，新增 KB-{N}}
[WRITE]      bug-experience-cards.csv (修改)
[TRANSITION] reviewing → done (devflow retrospect, 前驱合法)
[COMPLETE]   devflow retrospect — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
```

- [ ] **Step 3：在 fix.md 末尾追加**

```markdown
---

## 状态验证（前置条件扩展）

合法前驱状态：`done` 或 `coding`（已完成工作项也可触发 Bug 修复）。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow fix。
  合法前驱状态：done / coding
```

**注：** Bug 类型工作项（`meta.json.type = "bug"`）的 state-guard hook 会自动跳过 spec 文件拦截，允许在 `coding` 状态下直接写入 `spec/requirement.md`。

---

## 执行日志规范（progress.md 追加）

```
[START]      {ISO时间戳} devflow fix（issue: {issue_id}）
[READ]       context/sanitized.md
[DECISION]   {根因定位，如：根因在 XxxClass.method() 第 42 行，评分 93/100}
[DECISION]   {修复方案，如：最小改动：修改 null 判断逻辑，影响面 LOW}
[WRITE]      {修改的文件路径} (修改)
[TRANSITION] {done|coding} → coding (devflow fix, 前驱合法)
[COMPLETE]   devflow fix — {ISO时间戳}
```

异常退出时（如评分 < 90）：`[ERROR] 评分 {score}/100 低于准入门禁，命令中止`
```

- [ ] **Step 4：验证**

```bash
grep -l "执行日志规范" plugins/devflow/commands/review.md \
  plugins/devflow/commands/retrospect.md plugins/devflow/commands/fix.md | wc -l
```

期望：`3`

- [ ] **Step 5：提交**

```bash
git add plugins/devflow/commands/review.md \
        plugins/devflow/commands/retrospect.md \
        plugins/devflow/commands/fix.md
git commit -m "feat(robustness): review/retrospect/fix 新增状态验证和执行日志规范区块"
```

---

## 自检结果

**规格覆盖检查：**

| 规格要求 | 对应任务 | 覆盖 |
|---------|---------|------|
| progress.md 结构化格式 | Task 1 | ✅ |
| devflow-audit.sh（PostToolUse） | Task 2 | ✅ |
| devflow-state-guard.sh（PreToolUse + checkpoint） | Task 3 | ✅ |
| 状态机跃迁表（命令前置条件扩展） | Task 7-10 | ✅ |
| Checkpoint 回滚（continue 恢复模式） | Task 6 | ✅ |
| devflow audit 子命令 | Task 4 | ✅ |
| init hook 安装步骤 | Task 5 | ✅ |
| Bug 类型工作项跳过 spec 拦截 | Task 3（脚本）+ Task 10（fix.md） | ✅ |
| continue 读最后 25 条 | Task 6 | ✅ |
| 平台降级策略 | Task 4（audit.md）+ Task 5（init.md） | ✅ |

**占位符扫描：** 无 TBD / TODO，所有代码块包含完整内容。

**类型一致性：** hook 脚本读取 `meta.json.status` 字段名与 meta.tpl.json 中的 `"status"` 字段一致。状态值（analyzing / designing / planning / coding / reviewing / done）与跃迁表一致。
