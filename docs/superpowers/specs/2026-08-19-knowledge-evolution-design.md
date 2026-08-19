# DevFlow 知识自进化机制设计规格

> 设计日期：2026-08-19
> 优先级：C（价值可观测性）> B（质量腐烂防治）> A（召回精准度）
> 范围：知识库使用统计、效果反馈、写入时增强去重、存量批量整理

---

## 背景与目标

当前知识库（`bug-experience-cards.csv`）的核心问题：缺乏可观测性。没有使用记录、没有效果反馈、没有质量信号，无法判断哪些卡片有价值、哪些已成死重。

本设计引入**四个机制**形成完整知识质量闭环：

1. **召回日志**：每次召回写入独立使用日志，建立使用基线数据
2. **效果回填**：`retrospect` 阶段引导用户评价召回效果，outcome 数据驱动质量信号
3. **增强去重**：写入时三维相似度检测，从源头防止重复入库
4. **存量整理**：`prune` 清理低效卡，`dedupe` 合并重复卡

---

## 一、knowledge-usage.jsonl 数据结构

**文件路径：** `.devflow/config/templates/knowledge/knowledge-usage.jsonl`

每次召回追加一行 JSON，追加写入，禁止修改已有行。

### 字段定义

```jsonl
{"ts":"2026-08-19T10:23:01Z","card_id":"KB-003","work_item":"20260819-UserAvatarUpload","recalled_by":"plan","outcome":"unknown","outcome_ts":null,"outcome_note":""}
{"ts":"2026-08-19T14:05:33Z","card_id":"KB-007","work_item":"20260819-UserAvatarUpload","recalled_by":"plan","outcome":"applied","outcome_ts":"2026-08-19T16:41:00Z","outcome_note":"避免了异步竞态问题，按卡片要求补了单元测试"}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `ts` | ISO 8601 UTC | 召回时间 |
| `card_id` | string | 经验卡 ID，如 `KB-003` |
| `work_item` | string | 当前工作项 ID |
| `recalled_by` | string | 触发召回的命令：`plan` / `fix` / `manual` |
| `outcome` | enum | `unknown`（未回填）/ `applied`（用上了）/ `irrelevant`（不相关）/ `partial`（部分适用） |
| `outcome_ts` | ISO 时间戳或 null | 回填时间 |
| `outcome_note` | string | 用户简短说明（可为空） |

### 设计约束

- 追加写入，禁止修改已有行（保持日志完整性）
- `outcome` 初始值统一写 `unknown`，由 `retrospect` 回填
- 同一工作项对同一卡片的多次召回各自独立记录，不合并
- `devflow knowledge query` 手动查询**不写日志**（查询不等于用于任务决策）

---

## 二、召回日志写入（plan.md 改动）

### 写入时机

`plan.md` 步骤 2「Bug 经验召回」命中卡片后，在追加任务约束之前写入使用记录。

### 写入规范

```
每命中一张卡，向 knowledge-usage.jsonl 追加一条记录，字段：
  ts:          当前 ISO 时间戳
  card_id:     命中卡片的 ID
  work_item:   workspace.json.currentWorkItem
  recalled_by: "plan"
  outcome:     "unknown"
  outcome_ts:  null
  outcome_note: ""

未命中任何卡时不写入（注明「未召回 Bug 经验」）。
knowledge-usage.jsonl 不存在时先创建空文件再追加。
```

### fix.md 同步规则

`fix.md` 步骤 2 根因分析阶段若有显式经验召回，`recalled_by` 填 `"fix"`，其余字段规则相同。

---

## 三、写入时增强去重（retrospect.md 改动）

### 三维相似度检测

将现有「关键词重叠 > 70%」升级为三维检测，任一维度命中即触发：

| 维度 | 判断依据 | 命中阈值 |
|------|---------|---------|
| 标题相似 | title 关键词重叠 | > 60% |
| 根因相似 | root_cause + module **同时**匹配 | 两字段都命中 |
| 反模式相似 | anti_patterns 关键词重叠 | > 50% |

### 触发后展示对比视图

```
发现相似经验卡：KB-012（2026-03-10，HIGH，async 模块）
  根因：Promise 链未处理异常导致静默失败
  与当前草稿相似度：根因 + 反模式均重叠

选择处理方式：
1. 合并到 KB-012（AI 起草合并版本，保留两者最完整的字段）
2. 新增为独立卡（确认差异足够大，值得单独记录）
3. 放弃当前草稿（当前内容已被 KB-012 覆盖，无需新增）
```

### 选择 1（合并）时的 AI 起草规则

AI 起草合并卡需满足：
- `title`：取两者语义并集，用一句话概括
- `root_cause`：合并两者，保留各自的核心表述
- `anti_patterns`：合并为列表，去重
- `required_tests`：合并，取并集
- `severity`：取两者较高值
- `tags`：合并去重
- `module`：若相同保留；若不同取两者逗号拼接
- `created_at`：保留较早日期
- `last_reviewed`：更新为当前日期

用户确认后覆写原卡（保留其 ID），新草稿不入库。

---

## 四、outcome 回填（retrospect.md 新增步骤 0）

### 前置步骤 0：召回效果回填

在 retrospect 步骤 1「读取复盘素材」之前执行：

```
读取 knowledge-usage.jsonl，筛选：
  work_item = 当前工作项 且 outcome = "unknown"

若有记录，展示回填面板：

───────────────────────────────────────────
本次任务召回了以下经验卡，请评价实际效果：

[1] KB-003「Promise 未处理异常」→ 注入到 T004 实现约束
    a. 用上了，有帮助   b. 召回了但没用上   c. 不确定

[2] KB-007「金额精度 BigDecimal」→ 注入到 T009 验收项
    a. 用上了，有帮助   b. 召回了但没用上   c. 不确定
───────────────────────────────────────────

用户逐条选择后批量更新对应记录：
  a → outcome: "applied"，写入 outcome_ts
  b → outcome: "irrelevant"，写入 outcome_ts
  c → 保持 "unknown"，不写 outcome_ts

同时写入可选的 outcome_note（用户输入，回车跳过）。
```

无 unknown 记录时静默跳过，不打断正常复盘流程。

---

## 五、knowledge check 增强

`devflow knowledge check` 在现有字段完整性检查基础上，新增质量信号面板。

### 质量指标计算规则

- **有效率** = applied 次数 ÷（applied + irrelevant）次数，`unknown` 不计入分母；分母为 0 时显示「-」
- **沉睡卡** = 从未召回，或最近 90 天无召回记录
- **待观察卡** = 至少被召回 1 次，但 applied 率 < 30%
- **高价值卡** = 召回 ≥ 3 次 且 applied 率 ≥ 60%

### 输出格式

```
### Knowledge Base Quality Report
─────────────────────────────────────────────────
总览：{n} 张卡 · {n} 次历史召回 · 整体有效率 {n}%

── 高价值卡（召回≥3次 且 applied率≥60%）──────
  KB-003  Promise异常处理    召回 8次  有效 87%  最近: 3天前
  KB-007  金额精度           召回 5次  有效 80%  最近: 12天前

── 待观察卡（召回≥1次 但 applied率<30%）────────
  KB-015  Redis超时重试      召回 4次  有效 25%  → 建议复查内容
  KB-022  线程安全单例       召回 2次  有效 0%   → 建议考虑删除

── 沉睡卡（从未召回 或 90天无召回）──────────────
  KB-009  SQL注入防范        最后召回: 180天前  → 可能已过时
  KB-031  iOS内存泄漏        从未召回           → 确认是否仍适用

── 字段不健康卡（原有检查保留）─────────────────
  KB-012: Missing anti_patterns
  KB-018: Last reviewed > 6 months ago

建议操作：
  devflow knowledge prune   ← 清理沉睡卡和低效卡
  devflow knowledge dedupe  ← 扫描重复卡
```

---

## 六、knowledge prune 子命令

### 候选规则

满足任一即列出（不自动删除，逐条等待用户决定）：

| 类型 | 条件 |
|------|------|
| A「低效卡」 | 召回 ≥ 2 次 且 applied 率 = 0% |
| B「沉睡卡」 | 90 天内零召回 |
| C「未验证卡」 | 创建超 60 天且从未被召回 |

### 交互流程

```
Knowledge Prune — 候选清理列表（共 {n} 张）

[A] KB-022 线程安全单例（召回 2次，有效 0%）
    根因：单例模式未加锁导致多实例
    决定：1.删除  2.保留  3.更新内容后保留

[B] KB-009 SQL注入防范（最后召回: 180天前）
    根因：字符串拼接 SQL
    决定：1.删除  2.保留  3.标记为「归档」

[C] KB-031 iOS内存泄漏（从未召回，创建 75天）
    决定：1.删除  2.保留  3.触发手动召回验证
```

### 选项执行逻辑

| 选项 | 执行内容 |
|------|---------|
| 删除 | 从 CSV 移除；追加 `{"action":"pruned","reason":"user_confirmed"}` 到 jsonl |
| 归档 | CSV 的 tags 字段追加 `#archived`；check 不再计入统计，记录保留供查阅 |
| 更新后保留 | 进入 knowledge add 编辑流程；更新完成后追加 `{"action":"reset","reason":"content_updated"}` 事件，check 统计从该事件之后重新开始（历史记录保留不删除） |
| 触发验证 | 在 plan 下一次运行时强制展示该卡，要求确认是否仍适用 |

### 输出摘要

```
Prune 完成：已删除 {n} 张 · 已归档 {n} 张 · 已更新 {n} 张 · 已保留 {n} 张
```

---

## 七、knowledge dedupe 子命令

### 相似度扫描

对所有非归档卡片两两比较，使用与写入时相同的三维检测（标题 > 60% / root_cause+module 双命中 / anti_patterns > 50%）。卡片数 > 100 时提示扫描时间较长。

### 逐组处理流程

```
发现 {n} 组候选重复，逐组处理：

组 1/3：KB-003 vs KB-019（root_cause + anti_patterns 均重叠）

  KB-003（2026-01-10，HIGH，async）
    根因：Promise 链未处理异常导致静默失败
    反模式：裸 .then() 不加 .catch()

  KB-019（2026-05-22，MEDIUM，async）
    根因：async/await 缺少 try/catch 导致未捕获异常
    反模式：async 函数体无 try/catch

处理方式：
  1. 合并（AI 起草合并版本）
  2. 保留两者（差异足够大）
  3. 跳过本组（稍后再决定）
```

### 选择合并时的执行逻辑

1. AI 按第三节「合并起草规则」起草合并卡，展示给用户确认
2. 用户确认后：
   - 保留 ID 较小的卡（如 KB-003），内容更新为合并版
   - 从 CSV 删除 ID 较大的卡（KB-019）
   - knowledge-usage.jsonl 中 KB-019 的历史记录 `card_id` 更新为 KB-003
   - 追加合并事件：`{"ts":"...","card_id":"KB-019","action":"merged_into","target":"KB-003"}`

### 输出摘要

```
Dedupe 完成：扫描 {n} 张 · 发现 {n} 组候选 · 已合并 {n} 组 · 知识库净减少 {n} 张
```

---

## 八、命令改动清单

### A 类：重大改动

| 文件 | 改动内容 | 改动量 |
|------|---------|--------|
| `commands/knowledge.md` | 新增 `prune` / `dedupe` 子命令；`check` 新增质量信号面板 | +120 行 |
| `commands/retrospect.md` | 新增步骤 0（outcome 回填）；升级三维去重检测 | +40 行 |

### B 类：轻量改动

| 文件 | 改动内容 | 改动量 |
|------|---------|--------|
| `commands/plan.md` | 步骤 2 召回后追加写入 knowledge-usage.jsonl | +15 行 |

### C 类：新增文件

| 文件 | 说明 |
|------|------|
| `assets/templates/knowledge/knowledge-usage.jsonl` | 空文件，`devflow init` 初始化时自动创建 |

---

## 能力边界说明

1. **三维相似度基于关键词匹配**，不使用语义向量，可能漏判语义相近但措辞不同的卡片
2. **有效率依赖 retrospect 流程完整执行**，跳过 retrospect 的工作项不产生 outcome 数据，统计会偏低
3. **dedupe 两两比较复杂度为 O(n²)**，卡片数量 > 200 时响应时间可能较长，届时建议按 module 分批运行

---

*规格版本：v1.0 | 覆盖范围：知识库可观测性、质量防治、去重整理*
