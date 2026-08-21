---
name: devflow-metrics
description: DevFlow 效能度量报告。统计需求交付周期、缺陷率、AI 代码贡献比、评审通过率等核心指标，量化工具价值。当用户说「效能报告」「效能指标」「devflow metrics」时触发。
---

# devflow metrics — 效能度量报告

**用途：** 基于 `.devflow/metrics.jsonl` 和现有工作项数据，生成效能度量报告，支持自定义时间范围和飞书推送。

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
devflow metrics                  # 近 30 天（默认）
devflow metrics --days 90        # 指定天数
devflow metrics --push           # 终端报告 + 推送飞书群消息
```

参数可组合：`devflow metrics --days 90 --push`

---

## 执行步骤

### 1. 确定时间范围

- 未传入 `--days`：startDate = 当前时间 - 30d
- 传入 `--days {n}`：startDate = 当前时间 - {n}d（{n} 须为正整数，否则提示"--days 参数须为正整数"并中止）
- endDate = 当前时间

### 2. 读取 metrics.jsonl

读取 `.devflow/metrics.jsonl`：
- 文件不存在 → 进入降级模式（见步骤 3）
- 筛选 `ts` 在 `[startDate, endDate]` 范围内的记录，后续步骤仅使用筛选后的记录

### 3. 降级模式（数据不足时）

若 `metrics.jsonl` 不存在，或时间范围内有效记录 < 3 条，输出以下提示：

```
⚠️  数据积累不足（当前有效记录：{n} 条）。
   建议完成更多工作项后再查看完整效能报告。
   以下指标来自现有工作项文件，精度有限。
```

降级后仍从 `.devflow/work-items/` 下各工作项 `meta.json` 尝试推导可用指标：
- 交付周期：`status = done` 的工作项取 `updatedAt - startedAt`（天数）
- 工作项类型分布：按 `meta.json.type` 字段分组计数

其余指标（AI 贡献比、评审通过率等）显示 `--`。

### 4. 计算各指标

使用步骤 2 筛选后的 records 计算（降级时使用步骤 3 的推导数据）：

**交付概况：**
- **完成工作项数**：`event = work_item_done` 的记录数（降级时：`status = done` 的 meta.json 数量）
- **类型分布**：按 `type` 字段分组计数（feature / bug / tech / 其他）
- **交付周期均值**：所有 `work_item_done` 记录的 `totalDays` 均值，保留一位小数（无数据显示 `--`）
- **交付周期 P90**：对 `totalDays` 数组排序，取第 90 百分位，保留一位小数（记录数 < 10 时显示 `--`，样本不足）
- **缺陷率**：`type = bug` 记录数 / 总完成数 × 100%，整数（无数据显示 `--`）

**AI 提效：**
- **AI 代码贡献比**：`event = code_complete` 且 `aiGeneratedPct != null` 的记录的 `aiGeneratedPct` 均值，保留整数（无数据显示 `--`）
- **评审通过率**：`event = review_result` 中 `passed = true` 的记录数 / 所有 `review_result` 记录数 × 100%，整数（无数据显示 `--`）
- **平均迭代次数**：`event = review_result` 中 `iterationCount` 的均值，保留一位小数（跳过 null 值；无数据显示 `--`）

**阶段瓶颈（补充计算，可能不完整）：**

对时间范围内 `status = done` 的工作项，读取各自 `progress.md`，提取相邻 `[TRANSITION]` 行的时间差，按阶段分组计算均值。

条件：至少 3 个工作项有完整 `[TRANSITION]` 记录，否则该节显示 `--`。

取均值最长的两个阶段作为「最长停留阶段」和「其次」。

### 5. 渲染终端输出

```
DevFlow 效能报告   近 {n} 天（{YYYY-MM-DD} ~ {YYYY-MM-DD}）
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

数据不足的指标显示 `--`，其他指标正常展示。

若所有指标均为 `--`（完全无数据），输出完整分隔线和全 `--` 格式，不缩减区块。

### 6. 飞书推送（可选）

条件：传入 `--push` 且 `workspace.json.dashboardFeishuChatId` 不为空。

未配置时：
```
ℹ️  未配置飞书群 ID，跳过推送。
   可在 workspace.json 中设置 dashboardFeishuChatId 后重试。
```

已配置时：使用 lark-im skill 向 `{dashboardFeishuChatId}` 发送消息，消息内容为步骤 5 的完整终端输出文本。

---

## 输出示例

```
DevFlow 效能报告   近 30 天（2026-07-22 ~ 2026-08-21）
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
