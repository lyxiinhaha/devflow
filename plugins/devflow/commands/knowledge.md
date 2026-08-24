---
name: devflow-knowledge
description: DevFlow 团队知识库管理。支持 Bug 经验卡查询、添加和健康检查。当用户说「查询知识库」「沉淀经验」「知识库」「devflow knowledge」或想查找历史 bug 经验时触发。
---

# devflow knowledge — 团队知识库管理

**用途：** 管理 DevFlow 团队知识库和 Bug 经验卡，支持结构化查询（按 tag / module / severity）、添加、健康检查，可导出 JSON 格式。

---

## 前置条件

- `bug-experience-cards.csv` 存在（路径：`.devflow/config/templates/knowledge/bug-experience-cards.csv`）。

---

## 子命令

通过 `$ARGUMENTS` 传入，支持以下模式：

### 查询 `query` / `搜索 <关键词>`

**查询语法：**
```
query tag=security
query module=payment
query severity=CRITICAL
query <自然语言关键词>
```

按以下字段模糊匹配：`module`、`issue_type`、`root_cause`、`title`、`tags`。

输出匹配条目（限最多 10 条，超出提示用户细化条件）。

### 添加 `add`

通常由 `devflow retrospect` 自动触发，也可手动调用。

按 CSV 字段逐项提示用户填写，**以下字段不得为空**：
- `root_cause`（根本原因）
- `anti_patterns`（错误代码模式）
- `required_tests`（必须补充的测试）

写入前执行去重检查（见 retrospect 去重规则）。

### 健康检查 `check` / `健康检查`

1. 读取所有经验卡。
2. 检查缺失关键字段的「不健康」卡片：
   - `root_cause` 为空
   - `anti_patterns` 为空
   - `required_tests` 为空
   - `tags` 为空
3. 检查超过 6 个月未复核的卡片（`last_reviewed` 字段）。
4. 输出知识库概览。

### 导出 `export`

将知识库导出为 JSON 格式：
```json
[
  {
    "id": "KB-001",
    "type": "Bug Fix",
    "module": "async",
    "root_cause": "...",
    "anti_patterns": "...",
    "required_tests": "...",
    "prevention": "...",
    "severity": "HIGH",
    "tags": ["async", "promise", "race"]
  }
]
```

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
| 3. 更新后保留 | 进入 knowledge add 编辑流程；完成后向 `knowledge-usage.jsonl` 追加 `{"ts":"...","card_id":"...","action":"reset","reason":"content_updated"}`；check 统计从该事件之后重新开始（历史记录保留不删除） |
| 4. 归档 | 在 `tags` 字段末尾追加 `,#archived`；check 质量面板不再统计此卡，记录保留供查阅 |

**输出摘要：**

```
Prune 完成：已删除 {n} 张 · 已归档 {n} 张 · 已更新 {n} 张 · 已保留 {n} 张
```

### 去重合并 `dedupe`

扫描所有非归档（`tags` 不含 `#archived`）卡片，两两比较，检测候选重复组。

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

---

### 蒸馏 `distill [tag=xxx | module=xxx | --force]`

将积累到阈值的同类经验卡提炼为项目级规则，写入 `project-rules.md`，并标记参与卡为 `distilled=true`。

**执行步骤：**

**Step 1：读取候选卡**

读取 `bug-experience-cards.csv`，过滤条件：`tags` 不含 `#archived` 且 `distilled` 列不为 `"true"`。

- 有指定 `tag=xxx` 或 `module=xxx`：按该条件筛选
- 无参数：扫描所有 tag，统计各 tag 下的候选卡数，列出 ≥ threshold 的 tag 供用户选择

**Step 2：阈值检查**

读取 `.devflow/config/devflow.json` 中的 `knowledge.distillThreshold`（字段不存在时使用默认值 `3`）。

命中卡数 < threshold 且无 `--force` 参数：

```
当前 tag={tag} 有 {n} 张候选卡，低于蒸馏阈值（{threshold}）。
建议继续积累经验卡后再蒸馏，或使用 --force 强制执行。
```

**Step 3：规则冲突检查**

读取 `.devflow/config/templates/knowledge/project-rules.md`（不存在则跳过本步骤）。

提取新卡的 `tags` 字段（逗号分隔，trim 空格），对每个 tag 在规则文件全文做 **case-insensitive 完整词匹配**（前后为空白/标点/行首尾，非简单子字符串）。

- 命中任一 tag → 输出：
  ```
  ⚠️ 发现已有规则匹配 tag「{tag}」，当前 project-rules.md 中可能已覆盖此内容。
  建议先执行 devflow knowledge check 查看规则失效预警，再决定是否修订已有规则。
  如需强制新建规则，使用 --force 参数继续。
  ```
  无 `--force` 时退出；有 `--force` 时继续 Step 4。
- 未命中 → 继续 Step 4

**Step 4：AI 起草规则草稿**

汇总候选卡的字段，提炼共性内容：
- `anti_patterns` → 去重合并，提取禁令列表
- `required_tests` → 去重合并，提取必须项列表

起草规则草稿，格式如下：

```markdown
## {规则标题}（来源：{card_id_1}、{card_id_2}...，创建：{YYYY-MM-DD}）

{2-3 句描述原则和适用范围}

**禁止：**
- {合并各卡 anti_patterns 的共性禁令，每条一行}

**必须：**
- {合并各卡 required_tests 的共性要求，每条一行}
```

规则标题命名约定：`{模块/领域} + 核心约束动词 + 对象`，例：「埋点必须收口到模块级 object」

展示草稿，等待用户确认或修改后继续。

**Step 5：写入（用户确认后执行）**

1. 读取 `.devflow/config/templates/knowledge/project-rules.md`
   - 不存在：从 `plugins/devflow/assets/templates/knowledge/project-rules.tpl.md` 复制到运行时路径，再追加
   - 存在：直接追加规则章节到文件末尾
2. 逐行更新参与蒸馏的各卡：`distilled` 列 = `"true"`，`rule_ref` 列 = 规则标题
3. 向 `knowledge-usage.jsonl` 追加事件（每张参与卡一条）：
   ```json
   {"ts":"...","card_id":"{KB-xxx}","work_item":"...","action":"rule_distilled","rule_ref":"{规则标题}"}
   ```
4. 输出摘要：
   ```
   ✅ 规则已写入 project-rules.md
     规则标题：{标题}
     参与卡：{card_id 列表}（已标记 distilled=true）
     知识库中 distilled 卡数：{n} 张（不再参与 plan 阶段召回）
   ```

---

## 经验卡完整结构

```csv
id,created_at,last_reviewed,issue_type,module,title,root_cause,anti_patterns,required_tests,severity,tags
KB-001,2024-01-10,2024-07-01,race_condition,async,"标题",根因,反模式,测试要求,HIGH,"tag1,tag2"
```

---

## 输出示例（查询）

```
知识库搜索：「payment」
─────────────────────────────────────────
匹配到 3 条经验卡：

[CRITICAL] KB-015 金额精度丢失（2024-06-01）
  根因：直接使用 JS 浮点数进行金额运算
  禁止：使用 Float/Double 处理货币计算
  要求测试：金额边界值计算测试；与后端结果对比

[HIGH] KB-009 Token 过期未刷新（2024-04-01）
  ...
─────────────────────────────────────────
```

## 输出示例（健康检查）

```
### Knowledge Base Health Check
- **Total Cards**: {n}
- **Healthy Cards**: {n}
- **Issues Found**: {n}
  - KB-012: Missing `anti_patterns` field.
  - KB-018: Last reviewed > 6 months ago (2024-01-01).
- **Severity Distribution**: CRITICAL: 3, HIGH: 8, MEDIUM: 9
- **Last Updated**: {date}
```

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

── 蒸馏建议（同 tag 未蒸馏卡 ≥ distillThreshold）───────────────────────
  {tag}    {n} 张卡可蒸馏   → devflow knowledge distill tag={tag}
  （无候选时省略本节；候选条件：非归档 + distilled != "true" + 同 tag 数量 ≥ distillThreshold
    且 project-rules.md 中无对应 tag 的规则）

── 规则失效预警（已有规则出现同类新卡）────────────────────────────────
  规则「{rule_ref}」自建立后出现 {n} 次同类新卡
    最新：{card_id}（{created_at}）→ 建议复查规则是否需要加强
  （无失效预警时省略本节；读取 knowledge-usage.jsonl 中 action="rule_violated" 按 rule_ref 分组统计）

建议操作：
  devflow knowledge prune    ← 清理沉睡卡和低效卡
  devflow knowledge dedupe   ← 扫描重复卡
  devflow knowledge distill  ← 蒸馏同类卡为项目规则（蒸馏建议节有候选时显示）
```
