# DevFlow 可观测性增强实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 DevFlow 新增全局进度看板、效能度量体系和主动风险预警能力，解决管理者无法快速掌握项目全貌、工具价值无法量化、风险发现滞后三个问题。

**Architecture:** 三命令独立体系——新增 `devflow dashboard`（全局看板）和 `devflow metrics`（效能报告）两个命令；风险扫描逻辑提取为共享 skill `devflow-risk-scanner`，嵌入到 `continue/code/plan` 的命令入口；各命令完成时向 `.devflow/metrics.jsonl` 追加结构化事件，作为统一数据层。

**Tech Stack:** Markdown（DevFlow 命令规格）、JSON Lines（数据层）、飞书 OpenAPI（可选推送）

**Spec:** `docs/superpowers/specs/2026-08-20-devflow-observability-design.md`

---

## 文件结构

**新增文件：**
- `plugins/devflow/skills/devflow-risk-scanner/index.md` — 风险扫描共享逻辑（延期/高风险变更/依赖阻塞）
- `plugins/devflow/commands/dashboard.md` — 全局进度看板命令
- `plugins/devflow/commands/metrics.md` — 效能度量报告命令

**修改文件：**
- `plugins/devflow/commands/continue.md` — 步骤 1 后插入风险扫描调用
- `plugins/devflow/commands/code.md` — 步骤 1 后插入风险扫描调用；`[COMPLETE]` 前写入 `code_complete` 事件
- `plugins/devflow/commands/plan.md` — 步骤 1 后插入风险扫描调用；`[COMPLETE]` 前写入 `stage_complete` 事件
- `plugins/devflow/commands/analyze.md` — `[COMPLETE]` 前写入 `stage_complete` 事件
- `plugins/devflow/commands/design.md` — `[COMPLETE]` 前写入 `stage_complete` 事件
- `plugins/devflow/commands/review.md` — `[COMPLETE]` 前写入 `review_result` 事件
- `plugins/devflow/commands/fix.md` — `[COMPLETE]` 前写入 `bug_fixed` 事件
- `plugins/devflow/commands/init.md` — 新增 `dashboardFeishuChatId` / `dashboardSheetToken` 配置项
- `plugins/devflow/commands/README.md` — 新增 dashboard 和 metrics 条目

---

## Task 1：创建 devflow-risk-scanner 共享 skill

**Files:**
- Create: `plugins/devflow/skills/devflow-risk-scanner/index.md`

- [ ] **步骤 1：新建 skill 文件**

创建 `plugins/devflow/skills/devflow-risk-scanner/index.md`，写入以下完整内容：

```markdown
---
name: devflow-risk-scanner
description: DevFlow 风险扫描共享逻辑。由 devflow continue / devflow code / devflow plan 在步骤开头调用，扫描延期风险、高风险变更、依赖阻塞三类风险，有风险时输出警告块，无风险时静默。
---

# devflow-risk-scanner — 风险扫描共享逻辑

**用途：** 在关键命令入口执行轻量风险扫描，主动暴露延期/冲突/高影响变更风险，不阻断主流程。

---

## 调用方式

被其他命令内联引用，不单独由用户触发。调用方在执行主逻辑之前插入以下步骤：

```
执行风险扫描（依照 devflow-risk-scanner skill 逻辑）
```

---

## 扫描逻辑

所有扫描项均为**尽力而为**：文件不存在或数据不足时，静默跳过该项，不报错，不阻断主流程。

### 扫描项 1：延期风险

**数据来源：** 当前工作项 `spec/estimate.md`（若存在）、`meta.json.startedAt`

**计算：**
1. 从 `spec/estimate.md` 提取期望工时（单位：天，字段 `期望工时` 或 `expectedDays`）
2. 已耗时 = 当前时间 - `meta.json.startedAt`（天数，精确到 0.5d）
3. 判断：
   - 已耗时 > 悲观工时（`pessimisticDays`）→ **🔴 HIGH**：延期风险：已耗时 {x}d，超出悲观估算 {y}d
   - 已耗时 > 期望工时 × 1.2 → **🟡 MEDIUM**：延期风险：已耗时 {x}d，超出期望工时 20%

若 `spec/estimate.md` 不存在 → 静默跳过。

### 扫描项 2：高风险变更

**数据来源：** 当前工作项 `spec/design.md`（若存在）、`meta.json.status`

**逻辑：**
1. 从 `spec/design.md` 提取爆炸半径评级（字段 `风险等级` 或 `riskLevel`，值为 LOW/MEDIUM/HIGH/CRITICAL）
2. 若评级为 CRITICAL 或 HIGH，且 `meta.json.status = coding` → **🟡 MEDIUM**：高影响变更：爆炸半径评级 {等级}，建议 review 前补充集成测试

若 `spec/design.md` 不存在或无评级字段 → 静默跳过。

### 扫描项 3：依赖阻塞

**数据来源：** `.devflow/workspace.json`

**逻辑：**
1. 读取 `workspace.json.activeWorkItems`
2. 筛选 `sharedWith` 不为空的条目
3. 对每个冲突项，检查其 `status` 是否为 `coding`
4. 满足条件 → **🟡 MEDIUM**：依赖冲突：与 {冲突工作项ID} 共享 {sharedWith 字段值}，对方仍在编码中

若无活跃工作项或无 `sharedWith` 字段 → 静默跳过。

---

## 输出格式

**有风险时**，在命令主流程开始前输出警告块：

```
⚠️  风险预警（{n} 项）
  🔴 延期风险：已耗时 6.5d，超出悲观估算 5d
  🟡 依赖冲突：与 20260818-DetailPageSwitch 共享 TradeModule，对方仍在编码中
──────────────────────────────────────
继续执行 devflow {命令名} ...
```

**无风险时**：静默，不输出任何内容，直接进入主流程。

**扫描出错时**：静默跳过出错的扫描项，其他项继续执行。
```

- [ ] **步骤 2：自检 skill 文档**

检查以下四点，有问题就地修改：
- 三个扫描项的字段名和判断条件是否与 spec 一致
- 输出格式示例是否与 dashboard/metrics 的输出风格一致
- 无 TBD / TODO / 模糊描述
- 容错原则（静默跳过）在每个扫描项中均已标注

- [ ] **步骤 3：提交**

```bash
git add plugins/devflow/skills/devflow-risk-scanner/index.md
git commit -m "feat(observability): 新增 devflow-risk-scanner 共享风险扫描 skill"
```

---

## Task 2：嵌入风险扫描到 continue / code / plan

**Files:**
- Modify: `plugins/devflow/commands/continue.md`
- Modify: `plugins/devflow/commands/code.md`
- Modify: `plugins/devflow/commands/plan.md`

- [ ] **步骤 1：修改 continue.md**

在 `continue.md` 的 `### 1. 检查 workspace` 节末尾（即该节最后一行内容之后）、`### 2. 展示所有活跃工作项` 之前，插入以下新节：

```markdown
### 1.5 风险扫描（主动预警）

加载并执行 `devflow-risk-scanner` skill 逻辑，针对当前焦点工作项完成三类扫描：延期风险、高风险变更、依赖阻塞。

有风险时输出警告块（见 devflow-risk-scanner 输出格式规范），无风险时静默，不影响后续步骤。
```

- [ ] **步骤 2：修改 code.md**

在 `code.md` 的 `### 1. 创建 Worktree` 节末尾、第二个步骤标题之前，插入以下新节：

```markdown
### 1.5 风险扫描（主动预警）

加载并执行 `devflow-risk-scanner` skill 逻辑，针对当前工作项完成三类扫描：延期风险、高风险变更、依赖阻塞。

有风险时输出警告块（见 devflow-risk-scanner 输出格式规范），无风险时静默，不影响后续编码步骤。
```

- [ ] **步骤 3：修改 plan.md**

在 `plan.md` 的 `### 1. 文档分析` 节末尾、`### 2. Bug 经验召回` 之前，插入以下新节：

```markdown
### 1.5 风险扫描（主动预警）

加载并执行 `devflow-risk-scanner` skill 逻辑，针对当前工作项完成三类扫描：延期风险、高风险变更、依赖阻塞。

有风险时输出警告块（见 devflow-risk-scanner 输出格式规范），无风险时静默，不影响后续任务拆解步骤。
```

- [ ] **步骤 4：自检三个文件**

对每个文件：
- 确认插入位置正确（步骤序号连贯，未破坏原有步骤顺序）
- 确认引用的 skill 名称与 Task 1 创建的文件 `name` 字段一致（`devflow-risk-scanner`）

- [ ] **步骤 5：提交**

```bash
git add plugins/devflow/commands/continue.md plugins/devflow/commands/code.md plugins/devflow/commands/plan.md
git commit -m "feat(observability): continue/code/plan 入口嵌入风险扫描步骤"
```

---

## Task 3：为现有命令添加 metrics.jsonl 写入步骤

**Files:**
- Modify: `plugins/devflow/commands/analyze.md`
- Modify: `plugins/devflow/commands/design.md`
- Modify: `plugins/devflow/commands/plan.md`
- Modify: `plugins/devflow/commands/code.md`
- Modify: `plugins/devflow/commands/review.md`
- Modify: `plugins/devflow/commands/fix.md`

所有修改均遵循同一原则：在各命令**执行日志规范**小节的 `[COMPLETE]` 行之前，插入 metrics 写入说明块。

- [ ] **步骤 1：修改 analyze.md**

在 analyze.md 执行日志规范中 `[COMPLETE]   devflow analyze` 行之前，插入：

```markdown
**metrics.jsonl 写入（完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录（若文件不存在则新建）：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "stage_complete",
  "stage": "analyze",
  "durationMin": "{从 [START] 到 [COMPLETE] 的分钟数，无法计算时填 null}"
}
```
```

- [ ] **步骤 2：修改 design.md**

在 design.md 执行日志规范中 `[COMPLETE]   devflow design` 行之前，插入：

```markdown
**metrics.jsonl 写入（完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "stage_complete",
  "stage": "design",
  "durationMin": "{从 [START] 到 [COMPLETE] 的分钟数，无法计算时填 null}"
}
```
```

- [ ] **步骤 3：修改 plan.md**

在 plan.md 执行日志规范中 `[COMPLETE]   devflow plan` 行之前，插入：

```markdown
**metrics.jsonl 写入（完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "stage_complete",
  "stage": "plan",
  "durationMin": "{从 [START] 到 [COMPLETE] 的分钟数，无法计算时填 null}"
}
```
```

- [ ] **步骤 4：修改 code.md**

在 code.md 执行日志规范中全部任务完成后追加的 `[COMPLETE]   devflow code（全部任务）` 行之前，插入：

```markdown
**metrics.jsonl 写入（全部任务完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "code_complete",
  "aiGeneratedPct": "{本次编码中由 AI 直接生成的代码行占比（0-100整数），无法估算时填 null}",
  "filesChanged": "{本次编码修改的文件数量}"
}
```

`aiGeneratedPct` 说明：由 AI 根据本次编码过程自估，计算口径为「AI 直接生成并被采纳的代码行 / 总变更行数 × 100」，无需精确，粗估即可。
```

- [ ] **步骤 5：修改 review.md**

在 review.md 执行日志规范中 `[COMPLETE]   devflow review` 行之前，插入：

```markdown
**metrics.jsonl 写入（完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "review_result",
  "passed": "{true 表示审查通过，false 表示有阻断问题需修复}",
  "iterationCount": "{本次 review 是第几次迭代，首次填 1}"
}
```
```

- [ ] **步骤 6：修改 fix.md**

在 fix.md 执行日志规范中 `[COMPLETE]   devflow fix` 行之前，插入：

```markdown
**metrics.jsonl 写入（完成时）：**
向 `.devflow/metrics.jsonl` 追加一条记录：
```json
{
  "ts": "{ISO时间戳}",
  "workItemId": "{当前工作项ID}",
  "event": "bug_fixed",
  "severity": "{从 issue 详情提取的严重程度：critical/high/medium/low，未知时填 null}",
  "durationMin": "{从 [START] 到 [COMPLETE] 的分钟数，无法计算时填 null}"
}
```
```

- [ ] **步骤 7：自检六个文件**

对每个文件检查：
- 插入位置在 `[COMPLETE]` 行之前（保证完成时才写入，异常退出不写入）
- JSON 字段名与 spec 数据层规范一致（`stage_complete` / `code_complete` / `review_result` / `bug_fixed`）
- `workItemId` 来源均为当前工作项 ID（从 workspace.json.focus 读取）

- [ ] **步骤 8：提交**

```bash
git add plugins/devflow/commands/analyze.md plugins/devflow/commands/design.md \
        plugins/devflow/commands/plan.md plugins/devflow/commands/code.md \
        plugins/devflow/commands/review.md plugins/devflow/commands/fix.md
git commit -m "feat(observability): 各命令完成时写入 metrics.jsonl 事件"
```

---

## Task 4：创建 devflow dashboard 命令

**Files:**
- Create: `plugins/devflow/commands/dashboard.md`

- [ ] **步骤 1：新建 dashboard.md**

创建 `plugins/devflow/commands/dashboard.md`，写入以下完整内容：

```markdown
---
name: devflow-dashboard
description: DevFlow 全局进度看板。展示项目级进度总览、活跃工作项风险状态、风险汇总和待办看板，支持推送飞书群消息或更新飞书多维表格。当用户说「全局看板」「项目进度」「devflow dashboard」时触发。
---

# devflow dashboard — 全局进度看板

**用途：** 项目级全局进度看板，面向管理者快速掌握项目全貌，支持终端查看和飞书推送。

---

## 前置条件

- `.devflow/` 目录存在。
- `workspace.json` 可读。

不满足时输出：
```
✗ 未找到 DevFlow 工作区，请先执行 devflow init。
```

---

## 调用方式

通过 `$ARGUMENTS` 传入参数：

```
devflow dashboard              # 终端看板（默认）
devflow dashboard --push       # 终端看板 + 推送飞书群消息
devflow dashboard --sheet      # 终端看板 + 更新飞书多维表格
```

---

## 执行步骤

### 1. 读取所有工作项

扫描 `.devflow/work-items/`，读取每个子目录下的 `meta.json`，统计以下数量：
- **活跃**：`status` 不为 `done` 且在 `workspace.json.activeWorkItems` 中的工作项
- **已完成**：`status = done`
- **暂停**：有 meta.json 但不在 `activeWorkItems` 中且 `status != done`

### 2. 计算本周交付数和平均周期

读取 `.devflow/metrics.jsonl`（若存在）：
- **本周交付数**：筛选 `event = work_item_done` 且 `ts` 在本周（周一 00:00 至今）的记录数
- **平均周期**：所有 `event = work_item_done` 记录的 `totalDays` 均值，保留一位小数

若 `metrics.jsonl` 不存在或无有效记录，上述字段显示 `--`。

### 3. 对每个活跃工作项执行风险扫描

加载并执行 `devflow-risk-scanner` skill 逻辑，针对每个活跃工作项扫描三类风险，收集结果：
- 每个工作项的最高风险等级（无风险为 ✓）
- 全局风险汇总：HIGH 数量、MEDIUM 数量及分类标注

### 4. 识别待办看板条目

- **需评审**：`meta.json.status = coding` 且 `review.md` 不存在的工作项（即编码完成但未开始审查）
- **待部署**：`meta.json.status = reviewing` 且 `review.md` 中最后一次评审结论为通过（`passed: true`）的工作项

识别逻辑说明：`review.md` 存在性判断路径为 `.devflow/work-items/{workItemId}/review.md`。

### 5. 渲染终端输出

按以下格式输出：

```
DevFlow 项目看板   {YYYY-MM-DD HH:MM}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
进度总览
  活跃  {n} 个    已完成  {n} 个    暂停  {n} 个
  本周交付  {n} 个    平均周期  {x.x}d

活跃工作项                    阶段      风险      耗时
  {workItemId 截取末段}        {status}  {风险图标+描述}  {耗时d}
  ...

风险汇总
  🔴 HIGH    {n} 项（{分类描述}）
  🟡 MEDIUM  {n} 项（{分类描述}）
  （无 HIGH/MEDIUM 时显示：✅ 无高风险工作项）

待办看板
  需评审    [ {workItemId} ... ]
  待部署    [ {workItemId} ... ]
  （无对应条目时该行不显示）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**活跃工作项行风险图标规则：**
- 🔴 HIGH：红色，含风险类型简述（如"延期"）
- 🟡 MEDIUM：黄色，含风险类型简述（如"冲突"/"高影响"）
- ✓：无风险

**耗时计算：** `当前时间 - meta.json.startedAt`，精确到 0.5d。

### 6. 飞书推送（可选）

#### `--push`：推送群消息

条件：`workspace.json.dashboardFeishuChatId` 不为空。

未配置时输出提示后跳过推送：
```
ℹ️  未配置飞书群 ID，跳过推送。
   可在 workspace.json 中设置 dashboardFeishuChatId 后重试。
```

已配置时：将步骤 5 的终端输出内容作为消息文本，调用：
```bash
lark-cli im send --chat-id {dashboardFeishuChatId} --text "{看板内容}"
```

#### `--sheet`：更新多维表格

条件：`workspace.json.dashboardSheetToken` 不为空。

未配置时输出提示后跳过：
```
ℹ️  未配置飞书表格 token，跳过更新。
   可在 workspace.json 中设置 dashboardSheetToken 后重试。
```

已配置时：将活跃工作项列表（ID、阶段、风险等级、耗时）全量写入指定多维表格，覆盖 `活跃工作项` 名称的工作表。调用 `lark-base` 或 `lark-sheets` skill 完成写入，具体字段：

| 字段 | 值 |
|---|---|
| 工作项ID | workItemId |
| 标题 | meta.json.title |
| 阶段 | meta.json.status |
| 风险等级 | HIGH / MEDIUM / 无风险 |
| 耗时（天） | 当前时间 - startedAt |
| 更新时间 | 当前时间 |

---

## 输出（示例）

```
DevFlow 项目看板   2026-08-20 14:30
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
进度总览
  活跃  3 个    已完成  12 个    暂停  1 个
  本周交付  3 个    平均周期  4.2d

活跃工作项                    阶段      风险      耗时
  20260817-UserLogin          coding    🔴延期     6d
  20260818-DetailSwitch       designing 🟡冲突     2d
  20260819-PaymentFix         coding    ✓         1d

风险汇总
  🔴 HIGH    1 项（延期）
  🟡 MEDIUM  1 项（依赖冲突 1）

待办看板
  需评审    [ 20260819-PaymentFix ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

- [ ] **步骤 2：自检 dashboard.md**

逐项检查：
- 步骤 3 风险扫描引用 skill 名（`devflow-risk-scanner`）与 Task 1 一致
- 步骤 6 飞书推送的两个配置字段（`dashboardFeishuChatId` / `dashboardSheetToken`）与 Task 6（init.md 修改）中新增字段名一致
- 步骤 4 待办看板的判断逻辑无歧义（review.md 路径明确）
- 输出格式示例完整，无占位符

- [ ] **步骤 3：提交**

```bash
git add plugins/devflow/commands/dashboard.md
git commit -m "feat(observability): 新增 devflow dashboard 全局进度看板命令"
```

---

## Task 5：创建 devflow metrics 命令

**Files:**
- Create: `plugins/devflow/commands/metrics.md`

- [ ] **步骤 1：新建 metrics.md**

创建 `plugins/devflow/commands/metrics.md`，写入以下完整内容：

```markdown
---
name: devflow-metrics
description: DevFlow 效能度量报告。统计需求交付周期、缺陷率、AI 代码贡献比、评审通过率等核心指标，量化工具价值。当用户说「效能报告」「效能指标」「devflow metrics」时触发。
---

# devflow metrics — 效能度量报告

**用途：** 基于 `metrics.jsonl` 和现有工作项数据，生成效能度量报告，支持自定义时间范围和飞书推送。

---

## 前置条件

- `.devflow/` 目录存在。
- `workspace.json` 可读。

---

## 调用方式

通过 `$ARGUMENTS` 传入参数：

```
devflow metrics                  # 近 30 天（默认）
devflow metrics --days 90        # 指定天数
devflow metrics --push           # 终端报告 + 推送飞书群消息
```

---

## 执行步骤

### 1. 确定时间范围

- 未传入 `--days`：默认近 30 天（startDate = 当前时间 - 30d）
- 传入 `--days {n}`：startDate = 当前时间 - {n}d
- endDate = 当前时间

### 2. 读取 metrics.jsonl

读取 `.devflow/metrics.jsonl`：
- 文件不存在 → 进入降级模式（见步骤 3）
- 筛选 `ts` 在 `[startDate, endDate]` 范围内的记录

### 3. 降级模式（数据不足时）

若 `metrics.jsonl` 不存在，或时间范围内有效记录 < 3 条：

```
⚠️  数据积累不足（当前有效记录：{n} 条）。
   建议完成更多工作项后再查看完整效能报告。
   以下指标来自现有工作项文件，精度有限。
```

降级后仍尝试从 `meta.json` 推导可用指标（交付周期、工作项类型分布），其余指标显示 `--`。

### 4. 计算各指标

读取过滤后的 records，按以下规则计算：

**交付概况：**
- 完成工作项数：`event = work_item_done` 的记录数
- 类型分布：按 `type` 字段分组计数（feature / bug / tech）
- 交付周期均值：`totalDays` 均值，保留一位小数
- 交付周期 P90：对 `totalDays` 数组排序，取第 90 百分位，保留一位小数
- 缺陷率：`type = bug` 的记录数 / 总完成数 × 100%，无数据时显示 `--`

**AI 提效：**
- AI 代码贡献比：`event = code_complete` 记录中 `aiGeneratedPct` 的均值（跳过 null 值），保留整数
- 评审通过率：`event = review_result` 中 `passed = true` 的记录数 / 总 review 记录数 × 100%
- 平均迭代次数：`event = review_result` 中 `iterationCount` 均值，保留一位小数

**阶段瓶颈（需要 progress.md 数据，作为补充）：**
- 对时间范围内已完成的工作项，读取各自 `progress.md`，提取相邻 `[TRANSITION]` 行的时间差
- 按阶段分组计算均值
- 取均值最长的两个阶段作为"最长停留阶段"和"其次"
- 若 progress.md 数据不足（< 3 个工作项有完整 TRANSITION 记录），该节显示 `--`

### 5. 渲染终端输出

```
DevFlow 效能报告   近 {n} 天（{startDate} ~ {endDate}）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
交付概况
  完成工作项      {n} 个（feature {n} / bug {n} / tech {n}）
  需求交付周期    均值 {x.x}d   P90 {x.x}d
  缺陷率          {n}%（{bug数} / {总数}）

AI 提效
  AI 代码贡献比   均值 {n}%
  评审通过率      {n}%（{通过数} / {总数} 次一次通过）
  平均迭代次数    {x.x} 次

阶段瓶颈
  最长停留阶段    {阶段名}（均值 {x.x}d）
  其次            {阶段名}（均值 {x.x}d）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

数据不足的指标显示 `--`，不影响其他指标展示。

### 6. 飞书推送（可选）

条件：传入 `--push` 且 `workspace.json.dashboardFeishuChatId` 不为空。

未配置时：
```
ℹ️  未配置飞书群 ID，跳过推送。
   可在 workspace.json 中设置 dashboardFeishuChatId 后重试。
```

已配置时：将步骤 5 输出内容作为消息文本发送到群。调用：
```bash
lark-cli im send --chat-id {dashboardFeishuChatId} --text "{报告内容}"
```

---

## 输出（示例）

```
DevFlow 效能报告   近 30 天（2026-07-21 ~ 2026-08-20）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
交付概况
  完成工作项      12 个（feature 8 / bug 3 / tech 1）
  需求交付周期    均值 4.2d   P90 7.1d
  缺陷率          25%（3 / 12）

AI 提效
  AI 代码贡献比   均值 68%
  评审通过率      83%（10 / 12 次一次通过）
  平均迭代次数    1.4 次

阶段瓶颈
  最长停留阶段    design（均值 1.8d）
  其次            review（均值 1.2d）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

- [ ] **步骤 2：自检 metrics.md**

逐项检查：
- 各指标的 JSON 字段引用（`totalDays` / `aiGeneratedPct` / `iterationCount`）与 Task 3 写入规范一致
- 降级模式触发条件和提示文本清晰
- 飞书推送复用 `dashboardFeishuChatId`（与 dashboard 命令共用同一字段）
- 输出格式示例无占位符，数字格式一致（保留小数位数）

- [ ] **步骤 3：提交**

```bash
git add plugins/devflow/commands/metrics.md
git commit -m "feat(observability): 新增 devflow metrics 效能度量报告命令"
```

---

## Task 6：更新 init.md 和 README.md

**Files:**
- Modify: `plugins/devflow/commands/init.md`
- Modify: `plugins/devflow/commands/README.md`

- [ ] **步骤 1：修改 init.md — 新增配置项**

在 init.md 执行步骤中，找到生成 `workspace.json` 的位置（步骤说明初始化 workspace.json 的节，约在文件 715 行附近的 `workspace.json` 结构示例）。

在 `workspace.json` 结构示例的 JSON 中，在 `"checklistSkill"` 字段之后添加两个新字段：

```json
"dashboardFeishuChatId": null,
"dashboardSheetToken": null,
```

同时，在 init.md 的交互式配置引导节（询问 Meegle、YApi、reviewSkill 等配置的步骤之后），添加以下可选配置引导：

```markdown
4. **看板飞书推送配置**（可选）：

   询问用户：「是否配置飞书看板推送？配置后 devflow dashboard --push 可自动发送看板到指定群。」

   - 用户提供群 ID → 写入 `workspace.json.dashboardFeishuChatId`
   - 用户提供多维表格 token → 写入 `workspace.json.dashboardSheetToken`
   - 留空则跳过，可后续手动配置。
```

- [ ] **步骤 2：修改 README.md — 新增命令条目**

在 `plugins/devflow/commands/README.md` 的命令列表中，找到 `devflow list` 或 `devflow audit` 附近，插入两个新条目（按字母顺序或按功能分组，与现有风格保持一致）：

```markdown
| `devflow dashboard` | 全局进度看板，展示项目进度总览、风险汇总、待办看板，支持飞书推送 |
| `devflow metrics`   | 效能度量报告，统计交付周期、缺陷率、AI 贡献比、评审通过率等指标 |
```

- [ ] **步骤 3：自检两个文件**

- init.md：确认 `dashboardFeishuChatId` / `dashboardSheetToken` 字段名与 dashboard.md / metrics.md 中引用的字段名完全一致
- README.md：确认命令描述与实际命令规格一致，风格与其他条目一致

- [ ] **步骤 4：提交**

```bash
git add plugins/devflow/commands/init.md plugins/devflow/commands/README.md
git commit -m "feat(observability): init.md 新增看板推送配置项，README 新增命令说明"
```

---

## 自检（计划层面）

### Spec 覆盖检查

| Spec 需求 | 实现任务 |
|---|---|
| 数据层 metrics.jsonl 写入规范 | Task 3（6 个命令写入步骤） |
| devflow-risk-scanner 共享逻辑 | Task 1 |
| continue/code/plan 嵌入风险扫描 | Task 2 |
| devflow dashboard 终端 + 飞书推送 | Task 4 |
| devflow metrics 终端 + 飞书推送 | Task 5 |
| workspace.json 新增字段 | Task 6（init.md） |
| README 更新 | Task 6（README.md） |

所有 spec 需求均有对应任务，无遗漏。

### 类型一致性检查

- 风险扫描 skill 名：全程为 `devflow-risk-scanner` ✓
- workspace 字段：全程为 `dashboardFeishuChatId` / `dashboardSheetToken` ✓
- metrics.jsonl 事件类型：`stage_complete` / `code_complete` / `review_result` / `bug_fixed` / `work_item_done` ✓（`work_item_done` 由 devflow 状态机在工作项变为 done 时写入，超出本计划范围，可作为后续任务）
- 所有字段名在 Task 3、4、5 中引用一致 ✓

### 遗留项说明

`work_item_done` 事件（工作项完成时写入总耗时和类型）依赖状态机 done 状态的触发点，当前 DevFlow 无单独的"关闭工作项"命令。建议后续在 `devflow retrospect` 或新增的 `devflow close` 命令中补充该事件写入，本计划暂不覆盖，metrics 报告中 `work_item_done` 相关指标（交付周期、缺陷率）在此之前将显示 `--`。
