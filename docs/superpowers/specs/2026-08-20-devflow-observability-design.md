# DevFlow 可观测性增强设计规格

**版本：** v1.0  
**日期：** 2026-08-20  
**状态：** 已确认，待实现

---

## 背景与问题

DevFlow 当前缺失三个跨工作项维度的能力：

1. **无全局进度看板**：只有 `devflow list` 纯文本列表，管理者无法快速掌握项目全貌、风险汇总和待办状态。
2. **无效能度量体系**：无法统计需求交付周期、缺陷率、AI 提效占比、评审通过率等核心指标，工具价值无法量化。
3. **无主动风险预警**：只有执行到对应步骤的静态门禁，不会主动识别延期风险、高风险变更、依赖阻塞，风险发现滞后。

---

## 设计目标

- 管理者：通过 `devflow dashboard` 快速掌握项目全貌，支持推送飞书
- 开发者：关键命令入口自动感知风险，无需主动查询
- 效能数据：从现有文件推导 + 各命令完成时追加写入，逐步积累

---

## 方案选型

三命令独立体系，符合 DevFlow 已有单一职责命令风格：

| 组件 | 形式 |
|---|---|
| `devflow dashboard` | 新增命令，全局进度看板 |
| `devflow metrics` | 新增命令，效能度量报告 |
| 风险扫描模块 | 嵌入现有命令（continue / code / plan） |
| 数据层 | `.devflow/metrics.jsonl` 中央采集文件 |

---

## 一、数据层

### 文件：`.devflow/metrics.jsonl`

每行一条 JSON 事件，由各命令在关键节点追加写入：

```jsonl
{"ts":"2026-08-20T10:00:00Z","workItemId":"20260817-Foo","event":"stage_complete","stage":"analyze","durationMin":45}
{"ts":"2026-08-20T11:30:00Z","workItemId":"20260817-Foo","event":"review_result","passed":true,"iterationCount":1}
{"ts":"2026-08-20T12:00:00Z","workItemId":"20260817-Foo","event":"code_complete","aiGeneratedPct":72,"filesChanged":8}
{"ts":"2026-08-20T14:00:00Z","workItemId":"20260817-Foo","event":"work_item_done","totalDays":3,"type":"feature"}
```

### 各命令写入时机

| 命令 | 事件类型 | 关键字段 |
|---|---|---|
| `devflow analyze` 完成 | `stage_complete` | stage=analyze, durationMin |
| `devflow design` 完成 | `stage_complete` | stage=design, durationMin |
| `devflow plan` 完成 | `stage_complete` | stage=plan, durationMin |
| `devflow code` 完成 | `code_complete` | aiGeneratedPct, filesChanged |
| `devflow review` 完成 | `review_result` | passed, iterationCount |
| `devflow fix` 完成 | `bug_fixed` | severity, durationMin |
| 工作项状态变为 done | `work_item_done` | totalDays, type |

### 现有数据推导（无需写入）

- **交付周期**：`meta.json.updatedAt - startedAt`（status=done 时）
- **阶段停留时长**：`progress.md` 中相邻 `[TRANSITION]` 时间差
- **历史 Bug 数**：`bug-experience-cards.csv` 行数

---

## 二、主动风险预警模块

### 触发位置

在 `devflow continue`、`devflow code`、`devflow plan` 读取工作项状态之后、主流程之前插入。

### 三类风险扫描

**① 延期风险**
- 读取 `spec/estimate.md` 中期望工时（若存在）
- 已耗时 > 悲观工时 → 🔴 HIGH
- 已耗时 > 期望工时 × 1.2 → 🟡 MEDIUM

**② 高风险变更**
- 读取 `spec/design.md` 中爆炸半径评级
- CRITICAL 或 HIGH 且处于 coding 阶段 → 🟡 提示补充集成测试

**③ 依赖阻塞**
- 读取 `workspace.json.activeWorkItems`，找出 `sharedWith` 不为空项
- 冲突方仍在 coding → 🟡 提示共享模块名和冲突工作项 ID

### 输出格式

有风险时插入，无风险时静默：

```
⚠️  风险预警（2 项）
  🔴 延期风险：已耗时 6.5d，超出悲观估算 5d
  🟡 依赖冲突：与 20260818-DetailPageSwitch 共享 TradeModule，对方仍在编码中
──────────────────────────────────────
继续执行 devflow code ...
```

### 容错原则

扫描失败（文件不存在、数据不足）时静默跳过，不阻断主流程。

---

## 三、`devflow dashboard` 命令

### 用途

项目级全局进度看板，面向管理者快速掌握全貌。

### 调用方式

```
devflow dashboard              # 终端看板（默认）
devflow dashboard --push       # 终端看板 + 推送飞书群消息
devflow dashboard --sheet      # 终端看板 + 更新飞书多维表格
```

### 终端输出格式

```
DevFlow 项目看板   2026-08-20 14:30
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
进度总览
  活跃  5 个    已完成  12 个    暂停  2 个
  本周交付  3 个    平均周期  4.2d

活跃工作项                    阶段      风险      耗时
  20260817-UserLogin          coding    🔴延期     6d
  20260818-DetailPageSwitch   designing 🟡冲突     2d
  20260819-PaymentFix         coding    ✓         1d
  20260820-DarkMode           analyzing ✓         0.5d
  20260820-ApiRefactor        planning  🟡高影响   0.5d

风险汇总
  🔴 HIGH    1 项（延期）
  🟡 MEDIUM  2 项（依赖冲突 1，高影响变更 1）

待办看板
  需评审    [ 20260819-PaymentFix ]
  待部署    [ 20260815-ChatModule ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 飞书集成

**推送群消息（`--push`）：**
- 格式化为飞书消息卡片，发送到 `workspace.json.dashboardFeishuChatId`
- 未配置时提示：「请在 workspace.json 中配置 dashboardFeishuChatId」

**更新多维表格（`--sheet`）：**
- 将活跃工作项列表写入 `workspace.json.dashboardSheetToken` 指定的表格
- 每次全量覆盖当前活跃工作项行

### 执行步骤

1. 读取所有工作项 `meta.json`，计算各状态数量
2. 对每个活跃工作项执行风险扫描（复用预警模块逻辑）
3. 读取 `metrics.jsonl`，计算本周交付数和平均周期
4. 渲染终端输出
5. 若传入 `--push` 或 `--sheet`，调用对应飞书接口

---

## 四、`devflow metrics` 命令

### 用途

效能度量报告，量化工具价值与团队交付质量。

### 调用方式

```
devflow metrics                  # 默认：近 30 天
devflow metrics --days 90        # 指定时间范围
devflow metrics --push           # 终端 + 推送飞书群消息
```

### 指标体系

| 指标 | 计算来源 |
|---|---|
| 需求交付周期（均值/P90） | `metrics.jsonl` work_item_done.totalDays |
| 缺陷率（Bug 占比） | work_item_done.type=bug / 总工作项数 |
| AI 代码贡献比（均值） | code_complete.aiGeneratedPct 均值 |
| 评审通过率 | review_result.passed=true / 总评审次数 |
| 平均评审迭代次数 | review_result.iterationCount 均值 |
| 阶段瓶颈（最长停留） | progress.md TRANSITION 时间差，取各阶段均值 |

### 降级策略

- `metrics.jsonl` 不存在或记录 < 3 条 → 提示"数据积累不足，建议完成更多工作项后再查看"
- 单项指标缺数据 → 该行显示 `--`，不影响其他指标

### 终端输出格式

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

---

## 五、workspace.json 新增字段

```json
{
  "dashboardFeishuChatId": null,
  "dashboardSheetToken": null
}
```

`devflow init` 时可选配置，也可后续手动写入。

---

## 六、影响面评估

**新增文件：**
- `plugins/devflow/commands/dashboard.md`
- `plugins/devflow/commands/metrics.md`
- `plugins/devflow/skills/devflow-risk-scanner/`（风险扫描共享逻辑）

**修改文件：**
- `plugins/devflow/commands/continue.md`（步骤 1 后插入风险扫描调用）
- `plugins/devflow/commands/code.md`（步骤 1 后插入风险扫描调用；完成时写入 code_complete 事件）
- `plugins/devflow/commands/plan.md`（步骤 1 后插入风险扫描调用；完成时写入 stage_complete 事件）
- `plugins/devflow/commands/analyze.md`（完成时写入 stage_complete 事件）
- `plugins/devflow/commands/design.md`（完成时写入 stage_complete 事件）
- `plugins/devflow/commands/review.md`（完成时写入 review_result 事件）
- `plugins/devflow/commands/fix.md`（完成时写入 bug_fixed 事件）
- `plugins/devflow/commands/init.md`（新增 dashboardFeishuChatId / dashboardSheetToken 配置项）
- `plugins/devflow/commands/README.md`（新增两个命令的简介）

**不改动：**
- `devflow start`、`devflow switch`、`devflow audit`、`devflow knowledge` 等无关命令
- 工作项目录结构（`.devflow/work-items/`）

---

## 七、实现优先级建议

| 优先级 | 组件 | 原因 |
|---|---|---|
| P0 | 数据层（metrics.jsonl 写入规范） | 其他功能的数据基础，先建立采集再做展示 |
| P0 | 风险扫描模块 + 嵌入三个命令 | 开发者日常感知，高频使用路径 |
| P1 | `devflow dashboard` 终端版 | 管理者核心需求 |
| P1 | `devflow metrics` 终端版 | 效能量化核心需求 |
| P2 | 飞书推送集成（--push / --sheet） | 锦上添花，依赖 lark-im / lark-sheets |
