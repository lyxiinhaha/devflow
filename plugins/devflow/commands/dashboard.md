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

调用 `devflow-risk-scanner` skill，针对每个活跃工作项扫描三类风险，收集结果：
- 每个工作项的最高风险等级（无风险为 ✓）
- 全局风险汇总：HIGH 数量、MEDIUM 数量及分类标注

### 4. 识别待办看板条目

- **需评审**：`meta.json.status = coding` 且 `.devflow/work-items/{workItemId}/review.md` 不存在的工作项（即编码完成但未开始审查）
- **待部署**：`meta.json.status = reviewing` 且对应 `review.md` 中最后一次 `review_result` 事件的 `passed = true` 的工作项

### 5. 渲染终端输出

按以下格式输出（宽度以 48 字符为准，字段超长时截断）：

```
DevFlow 项目看板   {YYYY-MM-DD HH:MM}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
进度总览
  活跃  {n} 个    已完成  {n} 个    暂停  {n} 个
  本周交付  {n} 个    平均周期  {x.x}d

活跃工作项                    阶段      风险      耗时
  {workItemId 末段（最多20字符）} {status}  {风险图标}  {耗时d}
  ...

风险汇总
  🔴 HIGH    {n} 项（{分类描述}）
  🟡 MEDIUM  {n} 项（{分类描述}）
  （无 HIGH/MEDIUM 时显示：✅ 无高风险工作项）

待办看板
  需评审    [ {workItemId} ... ]
  待部署    [ {workItemId} ... ]
  （对应类别无条目时该行不显示）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**活跃工作项行风险图标规则：**
- 🔴 含风险类型简述（如"延期"）
- 🟡 含风险类型简述（如"冲突"/"高影响"）
- ✓：无风险

**耗时计算：** `当前时间 - meta.json.startedAt`，向下取整至 0.5d。

### 6. 飞书推送（可选）

#### `--push`：推送群消息

条件：`workspace.json.dashboardFeishuChatId` 不为空。

未配置时输出提示后跳过：
```
ℹ️  未配置飞书群 ID，跳过推送。
   可在 workspace.json 中设置 dashboardFeishuChatId 后重试。
```

已配置时：将步骤 5 的终端输出作为消息文本发送。调用：
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

已配置时：将活跃工作项列表全量写入指定多维表格，覆盖名为 `活跃工作项` 的工作表。使用 `lark-base` 或 `lark-sheets` skill 完成写入，字段如下：

| 字段 | 值 |
|---|---|
| 工作项ID | workItemId |
| 标题 | meta.json.title |
| 阶段 | meta.json.status |
| 风险等级 | HIGH / MEDIUM / 无风险 |
| 耗时（天） | 当前时间 - meta.json.startedAt，向下取整至 0.5d |
| 更新时间 | 当前时间（ISO格式） |

---

## 输出示例

```
DevFlow 项目看板   2026-08-21 10:00
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
