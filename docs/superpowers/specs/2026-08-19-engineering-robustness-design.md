# DevFlow 工程化鲁棒性设计规格

> 设计日期：2026-08-19
> 优先级：B（审计） > A（状态机） > C（回滚）
> 范围：生产级鲁棒性不足——独立审计、状态机强约束、断点回滚
> 并发安全：不在本次范围

---

## 背景与目标

DevFlow 当前的工程化短板：
- 状态机隐式化，AI 可跳过阶段，缺少强约束
- 无独立审计日志，出问题后只能靠 AI 自述追溯
- 命令中断后无自动回滚，留下脏状态需人工处理

本设计采用**双层方案**：
- **Hook 层**（Claude Code PreToolUse / PostToolUse）：独立于 AI，提供机械审计和状态硬拦截
- **progress.md 语义层**（AI 自述）：记录决策推理，补充 hook 无法捕获的语义信息

平台分层：Claude Code 获得硬约束，Cursor / Codex / OpenCode 自动降级为软约束（AI 自述），文档明示差异。

---

## 一、progress.md 结构化格式

### 文件头

由 `devflow start` 写入一次，不得重复写入：

```markdown
# Progress Log — {WorkItemId}
> 此文件由 DevFlow 自动维护，请勿手动编辑日志条目。

<!-- STATE_MACHINE: created→analyzing→designing→estimating→planning→coding→reviewing→done -->
```

### 日志条目规范

所有条目严格追加，禁止覆盖已有内容。

| 前缀 | 触发时机 | 示例 |
|------|---------|------|
| `[START]` | 命令开始执行 | `[START] 2026-08-19T10:23:01 devflow analyze` |
| `[READ]` | 读取关键文件 | `[READ] spec/requirement.md` |
| `[WRITE]` | 写入或修改文件 | `[WRITE] spec/design.md (新建)` |
| `[DECISION]` | 关键判断 | `[DECISION] 技术方案选 A，原因：现有架构已有 Redis，方案 B 引入新依赖` |
| `[TRANSITION]` | 状态跃迁成功 | `[TRANSITION] analyzing → designing (devflow design, 前驱合法)` |
| `[CHECKPOINT]` | 危险操作前（由 hook 写入 audit-log.jsonl，不写 progress.md） | — |
| `[ERROR]` | 执行异常中止 | `[ERROR] spec/design.md 不存在，前置条件不满足，命令中止` |
| `[COMPLETE]` | 命令正常结束 | `[COMPLETE] devflow analyze — 2026-08-19T10:31:45` |

### 追加规则（写入所有命令禁令区）

- 禁止覆盖 progress.md 已有内容
- 禁止静默跳过 `[TRANSITION]` 条目
- 命令异常退出时必须补写 `[ERROR]` 条目，不得留空
- `[DECISION]` 必须包含决策内容和原因，不得只写结论

### 示例完整片段

```
[START] 2026-08-19T10:23:01 devflow design
[READ] spec/requirement.md
[READ] context/sanitized.md
[DECISION] 技术方案选 A（缓存分层），原因：现有架构已有 Redis，方案 B 引入新依赖
[CHECKPOINT] → 由 hook 写入 audit-log.jsonl（见第二节）
[WRITE] spec/design.md (新建)
[TRANSITION] analyzing → designing (devflow design, 前驱合法)
[COMPLETE] devflow design — 2026-08-19T10:31:45
```

---

## 二、Hook 脚本

两个脚本由 `devflow init` 安装到 `.devflow/hooks/`，并注册到 Claude Code `settings.json`。

### `devflow-audit.sh`（PostToolUse）

每次 AI 工具调用结束后追加一条记录到 `.devflow/audit-log.jsonl`：

```bash
#!/bin/bash
# 环境变量由 Claude Code 注入：TOOL_NAME, TOOL_INPUT
WORK_ITEM=$(jq -r '.currentWorkItem // "none"' .devflow/workspace.json 2>/dev/null)
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tool\":\"$TOOL_NAME\",\"workItem\":\"$WORK_ITEM\",\"input\":$TOOL_INPUT}" \
  >> .devflow/audit-log.jsonl
```

记录工具名、工作项、操作路径或命令，不记录文件内容，控制日志体量。

### `devflow-state-guard.sh`（PreToolUse）

仅拦截 Write / Edit 工具调用，根据 meta.json 状态校验目标文件是否合法：

```bash
#!/bin/bash
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then exit 0; fi

WORK_ITEM=$(jq -r '.currentWorkItem // ""' .devflow/workspace.json 2>/dev/null)
if [[ -z "$WORK_ITEM" ]]; then exit 0; fi

STATUS=$(jq -r '.status' ".devflow/work-items/$WORK_ITEM/meta.json" 2>/dev/null)
TARGET=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

# 状态-文件映射表
case "$STATUS" in
  analyzing)  ALLOWED="spec/requirement.md|open-issues.md" ;;
  designing)  ALLOWED="spec/design.md|spec/api.md|open-issues.md" ;;
  planning)   ALLOWED="tasks.md|open-issues.md" ;;
  coding)     ALLOWED="progress.md|tasks.md" ;;
  reviewing)  ALLOWED="review.md|tasks.md|open-issues.md" ;;
  *)          exit 0 ;;
esac

# Bug 类型工作项跳过 spec 文件限制
WORK_ITEM_TYPE=$(jq -r '.type // ""' ".devflow/work-items/$WORK_ITEM/meta.json" 2>/dev/null)
if [[ "$WORK_ITEM_TYPE" == "bug" ]]; then exit 0; fi

if ! echo "$TARGET" | grep -qE "($ALLOWED)$"; then
  # 写入拦截记录到 audit-log
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tool\":\"$TOOL_NAME\",\"blocked\":true,\"reason\":\"状态拦截：$STATUS 不允许写入 $(basename $TARGET)\",\"workItem\":\"$WORK_ITEM\"}" \
    >> .devflow/audit-log.jsonl

  echo "⛔ DevFlow 状态拦截：当前状态 [$STATUS] 不允许写入 $(basename $TARGET)"
  echo "   合法写入目标：$ALLOWED"
  exit 1
fi

# 跃迁前写入 checkpoint
CHECKPOINT_DIR=".devflow/work-items/$WORK_ITEM/checkpoints"
mkdir -p "$CHECKPOINT_DIR"
cp ".devflow/work-items/$WORK_ITEM/meta.json" \
   "$CHECKPOINT_DIR/meta-$(date -u +%Y%m%dT%H%M%SZ).json"

# 只保留最近 10 份快照
ls -t "$CHECKPOINT_DIR"/meta-*.json | tail -n +11 | xargs rm -f 2>/dev/null
```

### 安装方式（`devflow init` 步骤 6.5）

```json
// .claude/settings.json（追加，不覆盖已有内容）
{
  "hooks": {
    "PostToolUse": [".devflow/hooks/devflow-audit.sh"],
    "PreToolUse":  [".devflow/hooks/devflow-state-guard.sh"]
  }
}
```

非 Claude Code 平台跳过 hook 安装，在 `devflow-profile.md` 注明「当前平台为软约束模式，状态校验依赖 AI 自述」。

---

## 三、状态机跃迁表

### 完整跃迁表

| 触发命令 | 合法前驱状态 | 跃迁到 | 备注 |
|---------|------------|--------|------|
| `devflow analyze` | `created` | `analyzing` | — |
| `devflow design` | `analyzing` | `designing` | — |
| `devflow estimate` | `designing` | `estimating` | 可选阶段 |
| `devflow plan` | `designing` / `estimating` | `planning` | estimate 可跳过 |
| `devflow code` | `planning` | `coding` | — |
| `devflow review` | `coding` | `reviewing` | — |
| `devflow retrospect` | `reviewing` | `done` | — |
| `devflow change` | 任意状态 | `analyzing` | 需求变更，强制回退 |
| `devflow fix` | `done` / `coding` | `coding` | Bug 修复，已完成工作项也可触发 |
| `devflow refactor` | `coding` / `done` | `coding` | — |
| `devflow continue` | 任意状态 | 不变 | 只读状态，不跃迁 |

### 特殊类型流程

**Bug 类型**：`created → coding → reviewing → done`，跳过 analyze / design / plan，state-guard 对 Bug 类型放行 spec 文件写入限制。

**Epic 类型**：`created → analyzing → designing → done`，无 planning / coding / reviewing 状态。

### 非法跃迁错误格式

AI 侧（命令前置条件）：
```
✗ 状态机拦截：当前状态 [coding] 不允许执行 devflow design。
  合法前驱状态：analyzing
  如需修改需求，请执行 devflow change。
```

Hook 侧（audit-log.jsonl 记录 + 终端输出）：
```
⛔ DevFlow 状态拦截：当前状态 [analyzing] 不允许写入 design.md
   合法写入目标：requirement.md|open-issues.md
```

---

## 四、Checkpoint 与回滚流程

### Checkpoint 触发时机

由 `devflow-state-guard.sh` 在验证通过、允许写入前自动执行，无需 AI 参与，不消耗 token。

### 目录结构

```
.devflow/work-items/{workItemId}/
└── checkpoints/
    ├── meta-20260819T091500Z.json   ← created → analyzing 前
    ├── meta-20260819T103200Z.json   ← analyzing → designing 前
    └── meta-20260819T142800Z.json   ← designing → planning 前
```

最多保留最近 10 份，hook 自动清理最旧快照。

### 两层回滚能力

| 回滚目标 | 方式 | 能力边界 |
|---------|------|---------|
| 状态回滚（meta.json） | 读取 checkpoints/ 最近快照还原 | ✅ 完全覆盖 |
| 文件内容回滚 | `git checkout .devflow/work-items/{id}/` | ✅ 有 git 时覆盖，无 git 不支持 |

### `devflow continue` 恢复流程

```
1. 读取 progress.md 最后 25 条条目（不读全文，控制 token）
2. 判断末尾条目类型：
   ├── [COMPLETE]         → 正常完成，提示执行下一命令
   ├── [ERROR]            → 识别中断点，进入恢复模式
   └── 其他（非 COMPLETE）→ 判断为异常中断，进入恢复模式
3. 恢复模式：
   a. 读取 checkpoints/ 最近快照与当前 meta.json 对比
   b. 若状态不一致，询问用户是否还原快照
   c. 展示中断现场摘要
   d. 提示三选项：继续 / 回滚 / 查看 audit
```

### 恢复模式展示

```
⚠️  检测到异常中断

  工作项：UserAvatarUpload
  中断位置：devflow design（2026-08-19 14:28）
  最后操作：[WRITE] spec/design.md（写入未完成）
  当前状态：designing
  上一稳定快照：analyzing（2026-08-19 10:32）

  可选操作：
  1. 继续完成 devflow design（从当前状态恢复）
  2. 回滚到 analyzing 状态重新执行 devflow design
  3. 查看完整中断日志（devflow audit --tail 25）

  选择 [1/2/3]：
```

---

## 五、`devflow audit` 子命令

### 调用方式

```bash
devflow audit               # 当前工作项摘要
devflow audit --tail 25     # 最近 25 条原始条目
devflow audit --blocked     # 仅展示被拦截操作
devflow audit --decisions   # 仅展示 AI 决策条目
devflow audit {workItemId}  # 指定工作项
```

### 数据来源

| 来源 | 内容 |
|------|------|
| `.devflow/audit-log.jsonl` | 工具调用、状态拦截（hook 写入） |
| `progress.md` `[DECISION]` 条目 | AI 决策语义（AI 写入） |

两个来源按时间戳合并排序后展示。

### 默认输出格式

```
DevFlow Audit — UserAvatarUpload
─────────────────────────────────────────────────
阶段轨迹：
  ✅ created     → analyzing   2026-08-19 09:15
  ✅ analyzing   → designing   2026-08-19 10:32
  ⚠️  designing  → planning    2026-08-19 14:28  （异常中断，未完成）

文件操作：15 次读取，4 次写入，1 次拦截

关键决策：
  [10:45] 技术方案选 A（缓存分层），原因：现有架构已有 Redis，方案 B 引入新依赖
  [11:20] 歧义 3 条：2 条 ControlledPass，1 条 HardBlocker 已阻断

被拦截操作：
  [14:28] ⛔ Write spec/design.md 被拦截 — 状态 analyzing 不允许写入

运行 `devflow audit --tail 25` 查看原始条目
```

### `--tail 25` 原始输出

```
2026-08-19T10:32:01Z  [TRANSITION]  analyzing → designing
2026-08-19T10:32:02Z  [READ]        spec/requirement.md
2026-08-19T10:45:18Z  [DECISION]    技术方案选 A，原因：...
2026-08-19T11:03:44Z  [WRITE]       spec/design.md (新建)
2026-08-19T14:28:05Z  [BLOCKED]     Write spec/design.md — 状态拦截
```

---

## 六、现有命令改动清单

### A 类：重大改动

**`devflow init`** — 新增步骤 6.5：

```
6.5 安装 Hook（仅 Claude Code 平台）
  - 将 devflow-audit.sh / devflow-state-guard.sh 写入 .devflow/hooks/
  - 追加 hooks 配置到 .claude/settings.json（不覆盖已有内容）
  - 非 Claude Code 平台跳过，在 devflow-profile.md 注明「软约束模式」
```

**`devflow continue`** — 全量重写恢复逻辑，见第四节。

### B 类：标准化改动

适用命令：`analyze` / `design` / `estimate` / `plan` / `code` / `review` / `retrospect` / `fix`

每个命令统一新增两个标准区块：

```markdown
### 状态验证（前置条件扩展）
读取 meta.json.status，对照跃迁表验证合法前驱状态。
非法时输出标准错误格式并中止，禁止继续执行。

### 执行日志（progress.md 追加规范）
- 命令启动：[START] {timestamp} devflow {command}
- 读取关键文件：[READ] {filepath}
- 写入文件：[WRITE] {filepath} ({新建|修改})
- 关键判断：[DECISION] {决策内容 + 原因}
- 状态跃迁：[TRANSITION] {from} → {to} ({command}, 前驱合法)
- 正常结束：[COMPLETE] devflow {command} — {timestamp}
- 异常退出：[ERROR] {原因}，命令中止
```

### C 类：新增文件

| 文件路径 | 说明 |
|---------|------|
| `commands/audit.md` | devflow audit 子命令实现，~80 行 |
| `assets/hooks/devflow-audit.sh` | PostToolUse hook 脚本，~20 行 |
| `assets/hooks/devflow-state-guard.sh` | PreToolUse hook 脚本，~40 行 |

### 改动文件汇总

| 文件 | 改动类型 | 改动量 |
|------|---------|--------|
| `commands/init.md` | 新增 hook 安装步骤 | +30 行 |
| `commands/continue.md` | 全量重写 | 全量 |
| `commands/audit.md` | 新建 | ~80 行 |
| `commands/analyze.md` 等 8 个 | 新增两个标准区块 | 每个 +15 行 |
| `assets/hooks/devflow-audit.sh` | 新建 | ~20 行 |
| `assets/hooks/devflow-state-guard.sh` | 新建 | ~40 行 |

---

## 七、平台分层策略

| 平台 | Hook 支持 | 约束级别 | 说明 |
|------|----------|---------|------|
| Claude Code | ✅ | 硬约束 | 状态拦截 + 独立审计 |
| Gemini CLI | ✅ 待适配 | 硬约束 | 需适配 hook 调用格式 |
| Cursor | ❌ | 软约束 | AI 自述，无独立审计 |
| Codex / OpenCode | ❌ | 软约束 | AI 自述，无独立审计 |

软约束平台：`devflow audit` 仍可用，但 audit-log.jsonl 为空，仅展示 progress.md 的 `[DECISION]` 条目。

---

## 能力边界说明

本设计诚实声明以下局限：

1. **决策审计依赖 AI 自述**：hook 记录工具调用行为，但 `[DECISION]` 条目的准确性和完整性取决于 AI 遵守规范，无独立验证机制
2. **文件内容回滚依赖 git**：checkpoint 只快照 meta.json 状态，文件内容回滚需 git 支持
3. **软约束平台无状态拦截**：Cursor 等平台状态跳步无法被硬拦截，只能靠前置条件文字提示

---

*规格版本：v1.0 | 覆盖范围：工程化鲁棒性（审计 + 状态机 + 回滚）*
