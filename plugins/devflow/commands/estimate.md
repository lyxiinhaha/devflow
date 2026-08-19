---
name: devflow-estimate
description: DevFlow 工作量估算。结合 CodeGraph 影响面数据科学估算工时，可更新 Meegle 排期。当用户说「工作量估算」「估算工时」「这个要做多久」「devflow estimate」时触发。
---

# devflow estimate — 工作量估算

**用途：** 结合 CodeGraph 影响面数据和历史 Bug 密度，为当前工作项提供三点置信区间估算，可选更新 Meegle 排期。

---

## 前置条件

- `spec/requirement.md` 已分析完成。
- `spec/design.md` 存在（含爆炸半径数据，建议完成设计后执行）。

---

## 执行步骤

### 1. 读取设计数据

读取 `spec/design.md` 中的爆炸半径评估数据，以及 `tasks.md`（若已生成）中的任务数量。

### 2. 历史 Bug 密度因子

读取 `bug-experience-cards.csv`，统计涉及模块的历史 Bug 密度：
- 该模块历史 Bug 数量较高（≥ 3 条经验卡命中）→ 基础估算 ×1.25（增加 25% buffer）
- 无历史记录 → 不调整

### 3. 估算模型

```
基础工时    = 任务数量 × 单任务基础工时（0.5h）
复杂度乘数  = LOW:1.0 / MEDIUM:1.5 / HIGH:2.5（取最高风险等级）
L0 储备    = 涉及 L0 模块时 × 1.2
Bug 密度储备 = 高密度模块 × 1.25
CRITICAL 储备 = CRITICAL 风险 × 1.3

期望工时   = 基础工时 × 复杂度乘数 × L0储备 × Bug密度储备 × CRITICAL储备
乐观工时   = 期望工时 × 0.7
悲观工时   = 期望工时 × 1.5
```

### 4. 明确排除项

估算**不包含**：QA 测试时间、部署时间、外部依赖等待时间、人工审批等待时间。

### 5. 可选：更新 Meegle 排期

若 `meta.json.linkedMeegleId` 存在，询问是否更新 Meegle 节点排期：

```bash
# 获取节点信息
meegle workflow get-node --work-item-id <id> --node-id-list '["_all"]'

# 更新排期（毫秒时间戳）
meegle workflow update-node \
  --work-item-id <id> \
  --node-id <node_key> \
  --node-schedule '{"estimate_start_date":<ms>,"estimate_end_date":<ms>}'
```

更新 `meta.json`：`stages.estimated = true`。

---

## 输出

```
📊 工作量估算报告
─────────────────────────────────────────
任务数：{n} 个
最高风险：{LOW | MEDIUM | HIGH | CRITICAL}
历史 Bug 密度：{高（+25% buffer）| 正常}
L0 模块：{是 | 否}

乐观估算：{x}h
期望估算：{y}h（推荐）
悲观估算：{z}h

排除项：QA 测试时间、部署时间、外部等待时间
Meegle 排期：{已更新 | 未配置}
─────────────────────────────────────────
下一步：使用 `devflow plan` 进行任务拆解。
```

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

执行期间，按以下规范向 `progress.md` 追加日志条目，不得覆盖已有内容：

```
[START]      {ISO时间戳} devflow estimate
[READ]       spec/design.md
[READ]       tasks.md（若已生成）
[READ]       bug-experience-cards.csv（若存在）
[DECISION]   {工作量估算结论，如：总计 ~40h，高风险任务 2 个（含三点估算）} — 原因：{简述}
[WRITE]      spec/estimate.md ({新建|修改})
[TRANSITION] designing → estimating ({触发本次跃迁的子命令名}, 依据 STATE_MACHINE 前驱合法)
[COMPLETE]   devflow estimate — {ISO时间戳}
```

异常退出时：`[ERROR] {原因}，命令中止`
