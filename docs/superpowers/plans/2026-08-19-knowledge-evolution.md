# DevFlow 知识自进化机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 DevFlow 知识库添加使用统计、AI 自动效果推断、三维增强去重、prune/dedupe 批量整理，使知识库质量可观测、可维护。

**Architecture:** 新增 `knowledge-usage.jsonl` 追加日志作为唯一数据源；`plan.md` 召回时写入记录；`retrospect.md` 新增步骤 0 静默自动推断 outcome；`knowledge.md` 扩展 check 质量面板并新增 prune / dedupe 两个子命令。所有改动均为 Markdown AI 指令文件追加/修改，不引入新依赖。

**Tech Stack:** Markdown（AI instruction files）、JSONL（追加日志）、CSV（经验卡存储）

**规格文档：** `docs/superpowers/specs/2026-08-19-knowledge-evolution-design.md`

---

## 文件结构

| 路径 | 操作 | 职责 |
|------|------|------|
| `plugins/devflow/assets/templates/knowledge/knowledge-usage.jsonl` | 新建 | 空模板文件，init 时复制到项目，召回和 retrospect 向此文件追加 |
| `plugins/devflow/commands/plan.md` | 修改 | 步骤 2 召回命中后追加写入使用记录 |
| `plugins/devflow/commands/retrospect.md` | 修改 | 新增步骤 0（AI 自动推断 outcome）+ 步骤 4 升级三维去重 |
| `plugins/devflow/commands/knowledge.md` | 修改 | check 新增质量信号面板；新增 prune / dedupe 子命令 |

---

## Task 1：新建 knowledge-usage.jsonl 模板

**Files:**
- Create: `plugins/devflow/assets/templates/knowledge/knowledge-usage.jsonl`

- [ ] **Step 1：检查目录是否存在**

```bash
ls plugins/devflow/assets/templates/knowledge/
```

期望：能看到 `bug-experience-cards.csv`（该目录已存在）。

- [ ] **Step 2：创建空模板文件**

写入 `plugins/devflow/assets/templates/knowledge/knowledge-usage.jsonl`，内容为：

```
# DevFlow 知识库使用日志
# 格式：每行一条 JSON 记录，追加写入，禁止修改已有行
# 字段：ts / card_id / work_item / recalled_by / outcome / outcome_ts / outcome_note
# outcome 枚举：unknown | applied | irrelevant | partial
```

- [ ] **Step 3：验证文件存在**

```bash
ls -la plugins/devflow/assets/templates/knowledge/knowledge-usage.jsonl
```

期望：文件存在，大小 > 0。

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/assets/templates/knowledge/knowledge-usage.jsonl
git commit -m "feat(knowledge): 新增 knowledge-usage.jsonl 使用日志模板文件"
```

---

## Task 2：更新 plan.md — 召回日志写入

**Files:**
- Modify: `plugins/devflow/commands/plan.md`

- [ ] **Step 1：读取 plan.md 步骤 2 末尾位置**

```bash
grep -n "命中经验卡\|注入位置记录\|步骤 3\|### 3\." plugins/devflow/commands/plan.md | head -10
```

找到「### 2. Bug 经验召回」结束、「### 2.5」或「### 3.」开始的位置。

- [ ] **Step 2：在步骤 2「Bug 经验召回」节末尾追加日志写入规范**

在「**注入位置记录（供输出展示用）：**」段落之后、下一个 `###` 标题之前，插入：

```markdown
### 召回日志写入

每命中一张经验卡，向 `bug-experience-cards.csv` 同级目录的 `knowledge-usage.jsonl` 追加一条记录：

```json
{
  "ts": "{ISO时间戳，如 2026-08-19T10:23:01Z}",
  "card_id": "{命中卡片的 ID，如 KB-003}",
  "work_item": "{workspace.json.currentWorkItem}",
  "recalled_by": "plan",
  "outcome": "unknown",
  "outcome_ts": null,
  "outcome_note": ""
}
```

**写入规则：**
- 每张命中卡独立追加一条记录，同一工作项对同一卡片多次命中各自独立记录
- `knowledge-usage.jsonl` 不存在时先创建（从 `assets/templates/knowledge/knowledge-usage.jsonl` 复制），再追加
- 未命中任何卡时不写入，注明「未召回 Bug 经验」即可
- `fix.md` 步骤 2 若有显式召回，`recalled_by` 填 `"fix"`，其余规则相同
```

- [ ] **Step 3：验证插入位置和关键词**

```bash
grep -n "recalled_by\|knowledge-usage.jsonl" plugins/devflow/commands/plan.md
```

期望：两个关键词均有输出，行号在步骤 2 对应区域。

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/commands/plan.md
git commit -m "feat(knowledge): plan 步骤 2 新增召回日志写入规范"
```

---

## Task 3：更新 retrospect.md — 步骤 0 + 三维去重

**Files:**
- Modify: `plugins/devflow/commands/retrospect.md`

### 3a：新增步骤 0（AI 自动推断 outcome）

- [ ] **Step 1：在「## 执行步骤」标题后、「### 1. 读取复盘素材」之前插入步骤 0**

找到 `### 1. 读取复盘素材` 这行，在其**正前方**插入：

```markdown
### 0. 自动推断召回效果（静默执行）

读取 `knowledge-usage.jsonl`，筛选 `work_item = 当前工作项` 且 `outcome = "unknown"` 的记录。

若无此类记录，跳过本步骤，不输出任何提示。

若有，从 `progress.md` 的 `[WRITE]` 条目提取本次修改的文件列表，读取对应文件关键改动内容，对每张卡按以下规则推断：

| outcome | 判断条件 |
|---------|---------|
| `applied` | 卡片 `module` 与修改文件模块重叠 **且** `required_tests` 关键词出现在新增测试文件中 |
| `irrelevant` | 卡片 `module` 与本次所有修改文件无任何模块交集 |
| `partial` | `module` 有交集，但 `required_tests` 未在测试文件中找到对应覆盖 |
| `unknown` | 无法从代码变更中判断（文件列表为空、模块信息缺失等） |

推断完成后批量更新对应记录：
- `outcome`：推断结果
- `outcome_ts`：当前 ISO 时间戳
- `outcome_note`：`"auto-inferred by retrospect"`

推断为 `unknown` 时不更新（保持原值）。**整个步骤 0 不输出任何提示，完全静默。**

```

- [ ] **Step 2：验证插入正确**

```bash
grep -n "步骤 0\|自动推断\|outcome_note" plugins/devflow/commands/retrospect.md
grep -n "### 1. 读取复盘" plugins/devflow/commands/retrospect.md
```

期望：步骤 0 的行号小于步骤 1 的行号。

### 3b：升级步骤 4 去重为三维检测

- [ ] **Step 3：替换步骤 4「去重检查」的检测逻辑**

找到步骤 4 当前内容（关键词：`相似 \`root_cause\`（关键词重叠度 > 70%）`），将步骤 4 整节替换为：

```markdown
### 4. 去重检查（三维相似度检测）

在写入前，对草稿执行三维检测，任一维度命中即触发提示：

| 维度 | 判断依据 | 命中阈值 |
|------|---------|---------|
| 标题相似 | `title` 关键词重叠 | > 60% |
| 根因相似 | `root_cause` + `module` 同时匹配 | 两字段都命中 |
| 反模式相似 | `anti_patterns` 关键词重叠 | > 50% |

发现相似卡时展示对比视图，提供三个选项：

```
发现相似经验卡：{已有卡 ID}（{创建日期}，{severity}，{module} 模块）
  根因：{已有卡 root_cause}
  与当前草稿相似度：{命中的维度描述}

选择处理方式：
1. 合并到 {已有卡 ID}（AI 起草合并版本，保留两者最完整的字段）
2. 新增为独立卡（确认差异足够大，值得单独记录）
3. 放弃当前草稿（当前内容已被已有卡覆盖，无需新增）
```

**选择 1（合并）时，AI 起草合并卡规则：**
- `title`：取两者语义并集，用一句话概括
- `root_cause`：合并两者，保留各自核心表述
- `anti_patterns`：合并为列表，去重
- `required_tests`：合并，取并集
- `severity`：取两者较高值
- `tags`：合并去重
- `module`：相同则保留；不同则逗号拼接
- `created_at`：保留较早日期；`last_reviewed`：更新为当前日期

起草完成后展示给用户确认，确认后覆写原卡（保留其 ID），当前草稿不入库。
```

- [ ] **Step 4：验证替换正确**

```bash
grep -n "三维\|> 60%\|> 50%" plugins/devflow/commands/retrospect.md
grep -n "70%" plugins/devflow/commands/retrospect.md
```

期望：第一条有输出，第二条无输出（旧的 70% 阈值已被替换）。

- [ ] **Step 5：提交**

```bash
git add plugins/devflow/commands/retrospect.md
git commit -m "feat(knowledge): retrospect 新增步骤 0 自动推断 outcome，升级三维去重检测"
```

---

## Task 4：更新 knowledge.md — check 增强 + prune + dedupe

**Files:**
- Modify: `plugins/devflow/commands/knowledge.md`

### 4a：增强 check 子命令

- [ ] **Step 1：找到 check 子命令的输出示例位置**

```bash
grep -n "### 健康检查\|check.*健康\|Health Check" plugins/devflow/commands/knowledge.md
```

- [ ] **Step 2：在 check 子命令末尾（输出示例之后）追加质量信号面板说明**

在「### 健康检查 `check`」节的输出示例之后插入：

```markdown
**质量信号面板（新增，在字段健康检查之后输出）：**

读取 `knowledge-usage.jsonl`（不存在时跳过质量面板，只输出字段健康检查）。

质量指标计算规则：
- **有效率** = `applied` 次数 ÷（`applied` + `irrelevant`）次数；`unknown` 不计入分母；分母为 0 时显示「-」
- **沉睡卡**：从未召回，或最近 90 天无召回记录
- **待观察卡**：至少被召回 1 次，但有效率 < 30%
- **高价值卡**：召回 ≥ 3 次 且 有效率 ≥ 60%

输出格式（追加在原有健康检查报告之后）：

```
── 高价值卡（召回≥3次 且 有效率≥60%）──────────────
  {card_id}  {title}    召回 {n}次  有效 {n}%  最近: {n}天前
  （无高价值卡时省略本节）

── 待观察卡（召回≥1次 但 有效率<30%）────────────────
  {card_id}  {title}    召回 {n}次  有效 {n}%  → 建议复查内容
  （无待观察卡时省略本节）

── 沉睡卡（从未召回 或 90天无召回）──────────────────
  {card_id}  {title}    最后召回: {n}天前 / 从未召回  → 确认是否仍适用
  （无沉睡卡时省略本节）

整体：{n} 次历史召回 · 整体有效率 {n}%（-表示暂无反馈数据）

建议操作：
  devflow knowledge prune   ← 清理沉睡卡和低效卡
  devflow knowledge dedupe  ← 扫描重复卡
```
```

### 4b：新增 prune 子命令

- [ ] **Step 3：在「### 导出 `export`」节之后追加 prune 子命令**

```markdown
### 清理 `prune`

**候选规则（满足任一即列出）：**

| 类型 | 条件 |
|------|------|
| A「低效卡」 | 召回 ≥ 2 次 且 `applied` 率 = 0% |
| B「沉睡卡」 | 90 天内零召回 |
| C「未验证卡」 | 创建超 60 天且从未被召回 |

`knowledge-usage.jsonl` 不存在时输出「暂无使用数据，无法生成候选列表」并退出。

**交互流程：**

逐张展示候选卡，等待用户逐条决定，不自动删除：

```
Knowledge Prune — 候选清理列表（共 {n} 张）

[{类型}] {card_id} {title}（{候选原因简述}）
  根因：{root_cause}
  决定：1.删除  2.保留  3.更新内容后保留  4.归档
```

**选项执行逻辑：**

| 选项 | 执行内容 |
|------|---------|
| 1. 删除 | 从 `bug-experience-cards.csv` 移除该行；向 `knowledge-usage.jsonl` 追加 `{"ts":"...","card_id":"...","action":"pruned","reason":"user_confirmed"}` |
| 2. 保留 | 不做任何变更 |
| 3. 更新后保留 | 进入 knowledge add 的编辑流程；完成后向 `knowledge-usage.jsonl` 追加 `{"ts":"...","card_id":"...","action":"reset","reason":"content_updated"}`；check 统计从该事件之后重新开始（历史记录保留不删除） |
| 4. 归档 | 在 `tags` 字段末尾追加 `,#archived`；check 质量面板不再统计此卡，记录保留供查阅 |

**输出摘要：**
```
Prune 完成：已删除 {n} 张 · 已归档 {n} 张 · 已更新 {n} 张 · 已保留 {n} 张
```
```

### 4c：新增 dedupe 子命令

- [ ] **Step 4：在 prune 子命令之后追加 dedupe 子命令**

```markdown
### 去重合并 `dedupe`

扫描所有非归档（tags 不含 `#archived`）卡片，两两比较，检测候选重复组。

**三维检测规则（与 retrospect 步骤 4 一致）：**

| 维度 | 命中阈值 |
|------|---------|
| `title` 关键词重叠 | > 60% |
| `root_cause` + `module` 同时匹配 | 两字段都命中 |
| `anti_patterns` 关键词重叠 | > 50% |

任一维度命中 → 标记为候选重复组。卡片数 > 100 时提示「扫描可能需要较长时间，建议按 module 分批运行：`devflow knowledge dedupe module=async`」。

**逐组处理流程：**

```
发现 {n} 组候选重复，逐组处理：

组 {i}/{n}：{card_id_A} vs {card_id_B}（{命中维度描述}）

  {card_id_A}（{created_at}，{severity}，{module}）
    根因：{root_cause}
    反模式：{anti_patterns}

  {card_id_B}（{created_at}，{severity}，{module}）
    根因：{root_cause}
    反模式：{anti_patterns}

处理方式：
  1. 合并（AI 起草合并版本）
  2. 保留两者（差异足够大）
  3. 跳过本组（稍后再决定）
```

**选择 1（合并）时执行逻辑：**

AI 起草合并卡（规则同 retrospect 步骤 4 合并规则）展示给用户确认。用户确认后：
1. 用合并内容覆写 ID 较小的卡（如 `KB-003`）
2. 从 `bug-experience-cards.csv` 删除 ID 较大的卡（如 `KB-019`）
3. 将 `knowledge-usage.jsonl` 中 `KB-019` 的历史记录 `card_id` 字段更新为 `KB-003`
4. 向 `knowledge-usage.jsonl` 追加合并事件：`{"ts":"...","card_id":"KB-019","action":"merged_into","target":"KB-003"}`

**输出摘要：**
```
Dedupe 完成：扫描 {n} 张 · 发现 {n} 组候选 · 已合并 {n} 组 · 知识库净减少 {n} 张
```
```

- [ ] **Step 5：验证所有新增内容存在**

```bash
grep -n "prune\|dedupe\|quality\|高价值卡\|merged_into" plugins/devflow/commands/knowledge.md
```

期望：5 个关键词均有输出。

- [ ] **Step 6：验证原有 query / add / check / export 子命令未被破坏**

```bash
grep -n "^### 查询\|^### 添加\|^### 健康检查\|^### 导出" plugins/devflow/commands/knowledge.md
```

期望：4 个标题均存在。

- [ ] **Step 7：提交**

```bash
git add plugins/devflow/commands/knowledge.md
git commit -m "feat(knowledge): check 新增质量信号面板，新增 prune 和 dedupe 子命令"
```

---

## 自检结果

**规格覆盖检查：**

| 规格章节 | 对应任务 | 覆盖 |
|---------|---------|------|
| 一、knowledge-usage.jsonl 数据结构 | Task 1 | ✅ |
| 二、召回日志写入（plan.md） | Task 2 | ✅ |
| 二、写入时增强去重（retrospect.md 步骤 4） | Task 3b | ✅ |
| 三、outcome 自动推断（retrospect.md 步骤 0） | Task 3a | ✅ |
| 四、knowledge check 增强 | Task 4a | ✅ |
| 五、knowledge prune | Task 4b | ✅ |
| 六、knowledge dedupe | Task 4c | ✅ |
| 七、命令改动清单 | 全部任务 | ✅ |

**占位符扫描：** 无 TBD / TODO。所有代码块包含完整内容。

**类型一致性：** `knowledge-usage.jsonl` 字段名（`ts`/`card_id`/`work_item`/`recalled_by`/`outcome`/`outcome_ts`/`outcome_note`）在 Task 1 模板文件、Task 2 写入规范、Task 3 推断规则、Task 4 统计逻辑中保持一致。合并事件 `action` 字段值（`pruned`/`reset`/`merged_into`）在 Task 4b/4c 中命名一致。
