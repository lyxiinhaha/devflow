---
name: devflow-risk-scanner
description: DevFlow 风险扫描共享逻辑。由 devflow continue / devflow code / devflow plan 在步骤开头调用，扫描延期风险、高风险变更、依赖阻塞三类风险，有风险时输出警告块，无风险时静默。
---

# devflow-risk-scanner — 风险扫描共享逻辑

**用途：** 在关键命令入口执行轻量风险扫描，主动暴露延期/冲突/高影响变更风险，不阻断主流程。

---

## 调用方式

被其他命令内联引用，不单独由用户触发。调用方在执行主逻辑之前插入以下步骤：

> 执行风险扫描（依照 devflow-risk-scanner skill 逻辑）

---

## 扫描逻辑

所有扫描项均为**尽力而为**：文件不存在或数据不足时，静默跳过该项，不报错，不阻断主流程。

### 扫描项 1：延期风险

**数据来源：** 当前工作项 `spec/estimate.md`（若存在）、`meta.json.startedAt`

**计算：**
1. 从 `spec/estimate.md` 提取期望工时（单位：天，字段 `期望工时` 或 `expectedDays`）和悲观工时（字段 `悲观工时` 或 `pessimisticDays`）
2. 已耗时 = 当前时间 - `meta.json.startedAt`（天数，精确到 0.5d）
3. 判断：
   - 已耗时 > 悲观工时 → **🔴 HIGH**：延期风险：已耗时 {x}d，超出悲观估算 {y}d
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
