---
name: devflow-audit
description: DevFlow 审计日志查询。合并展示 audit-log.jsonl（hook 独立记录）和 progress.md [DECISION] 条目，输出阶段轨迹、文件操作统计、关键决策和被拦截操作。当用户说「审计日志」「查看操作记录」「devflow audit」或需要追溯 AI 操作历史时触发。
---

# devflow audit — 审计日志查询

**用途：** 合并两个数据源（hook 独立审计 + AI 决策自述）输出可读的操作摘要，支持按工作项、事件类型过滤。

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

`currentWorkItem` 字段不存在或为 null 时，提示：「当前无活跃工作项，请传入 workItemId 参数。」

### 2. 读取数据源

**来源 A：** `.devflow/audit-log.jsonl`（hook 写入，每行一条 JSON）

若文件不存在或为空，说明当前平台不支持 hook（Cursor / Codex / OpenCode 等软约束平台），输出：
```
⚠️  当前平台为软约束模式，audit-log.jsonl 为空。
    仅展示 progress.md 中的 AI 决策记录。
```

**来源 B：** `.devflow/work-items/{workItemId}/progress.md`

提取所有以 `[DECISION]`、`[TRANSITION]`、`[ERROR]`、`[COMPLETE]` 开头的行。

`progress.md` 不存在时静默跳过来源 B，仅使用来源 A 数据。

### 3. 合并并展示

按时间戳升序合并两个来源。

若两个来源均无有效内容，输出：
「{workItemId} 暂无审计记录。该工作项可能尚未开始执行，或当前平台不支持 hook 且 progress.md 无结构化条目。」

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
- 某状态有对应 `[TRANSITION]` 条目，且后续存在 `[COMPLETE]` → ✅
- 某状态有 `[TRANSITION]` 但后续无 `[COMPLETE]`，或末尾条目为 `[ERROR]` → ⚠️（异常中断）

（默认摘要使用 [HH:MM] 短格式增强可读性，--tail 25 使用完整 ISO 时间戳）

#### `--tail 25` 原始输出格式

读取 `audit-log.jsonl` 最后 25 行 + `progress.md` 最后 25 个结构化条目，合并后按时间戳排序展示：

```
{ISO时间戳}  [{EVENT_TYPE}]  {内容}
```

#### `--blocked` 输出

仅展示 `audit-log.jsonl` 中 `blocked: true` 的条目：

```
被拦截操作列表（共 {n} 次）：
{ISO时间戳}  ⛔ {tool} {target} — {reason}
```

（无拦截记录时输出：「未发现被拦截操作。」）

#### `--decisions` 输出

仅展示 `progress.md` 中 `[DECISION]` 条目：

```
AI 决策记录（共 {n} 条）：
{ISO时间戳}  {DECISION 内容}
```

（无决策记录时输出：「未找到 [DECISION] 条目。」）

---

## 软约束模式降级

`audit-log.jsonl` 为空（非 Claude Code 平台）时：
- 阶段轨迹从 `progress.md` `[TRANSITION]` 条目提取
- 文件操作统计从 `progress.md` `[READ]` / `[WRITE]` 条目提取
- 被拦截操作节省略（无独立记录）
- 在摘要底部注明「数据来源：progress.md（软约束模式）」
