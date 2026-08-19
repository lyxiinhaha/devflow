---
name: devflow-retrospect
description: DevFlow 强制复盘节点。自动生成经验卡草稿，引导入库，知识库动态生长。当用户说「复盘」「经验沉淀」「devflow retrospect」，或由 devflow-fix / review / refactor 完成后自动触发。
---

# devflow retrospect — 强制复盘

**用途：** 在 Bug 修复、重构或复杂需求完成后自动触发，生成经验卡草稿，去重验证后入库，知识库动态生长，可选关闭 Meegle 工作项。

---

## 触发条件

以下任一情况自动触发（无需用户手动调用）：
- `devflow fix` 完成且验证通过
- `devflow review` 完成后发现需要沉淀的问题
- `devflow refactor` 完成且基线一致性通过
- CRITICAL 级别 Bug 修复完成
- 用户主动调用

---

## 前置条件

- 相关工作已完全完成并验证。
- 当前工作项 `context/sanitized.md`、`spec/design.md`（若存在）、`review.md`（若存在）、`progress.md` 可读。

---

## 执行步骤

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

### 1. 读取复盘素材

读取当前工作项：
- `context/sanitized.md`（需求/Bug 描述）
- `spec/design.md`（技术决策，若存在）
- `review.md`（审查结果，若存在）
- `progress.md`（操作日志）

### 2. 选择复盘模板

根据工作项类型选择模板：

| 类型 | 模板重点 |
|------|---------|
| Bug Fix | 根因分析、检测盲区、防复发措施 |
| Feature / Tech | 技术权衡、引入的技术债、经验教训 |
| Architecture | 架构决策依据、风险评估、演化路径 |
| Refactor | 重构收益、风险控制、后续建议 |

### 3. 生成经验卡草稿

提取以下字段：

```csv
id,created_at,last_reviewed,issue_type,module,title,root_cause,anti_patterns,required_tests,severity,tags
```

| 字段 | 说明 | 约束 |
|------|------|------|
| `root_cause` | 根本原因 | **不得为空** |
| `anti_patterns` | 导致问题的错误代码模式 | **不得为空** |
| `required_tests` | 必须补充的测试场景 | **不得为空** |
| `severity` | CRITICAL / HIGH / MEDIUM / LOW | 必填 |
| `tags` | 逗号分隔的关键词 | 至少 1 个 |

向用户展示草稿，允许修改。

### 4. 去重检查

在写入前，扫描 `bug-experience-cards.csv` 中是否存在：
- 相同 `title` 的条目
- 相似 `root_cause`（关键词重叠度 > 70%）

发现疑似重复时：
- 展示已有条目，询问用户是否更新现有卡片，还是新增一条
- 不得静默跳过或重复写入

### 5. 用户确认与入库

用户确认后，将经验卡追加到 `bug-experience-cards.csv`，分配递增 ID（`KB-{N+1}`）。

更新 `meta.json`：`stages.retrospected = true`，`status → done`。

### 6. 可选：关闭 Meegle 工作项

若 `meta.json.linkedMeegleId` 存在：
```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
```

---

## 输出

```
### Retrospect Completed
- **Type**: {Bug Fix | Feature | Architecture | Refactor}
- **Card ID**: KB-{N}
- **Root Cause**: {一句话描述}
- **Prevention Added**: {新增的防复发措施}

✅ 复盘完成，经验已沉淀至团队知识库。
  新增经验卡：{n} 条
  知识库总量：{n} 条
  Meegle 工作项：{已关闭 | 未配置}

这将在未来的 devflow plan 中自动召回。
```

---

## 状态验证（前置条件扩展）

合法前驱状态：`reviewing`。

非法时：
```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow retrospect。
  合法前驱状态：reviewing
```

---

## 执行日志规范（progress.md 追加）

执行期间，按以下规范向 `progress.md` 追加日志条目，不得覆盖已有内容：

```
[START]      {ISO时间戳} devflow retrospect
[READ]       context/sanitized.md
[READ]       review.md
[DECISION]   {经验卡核心内容，如：根因为 XX 反模式，新增 KB-{N}} — 原因：{简述}
[WRITE]      bug-experience-cards.csv (修改)
[TRANSITION] reviewing → done (retrospect, 依据 STATE_MACHINE 前驱合法)
[COMPLETE]   devflow retrospect — {ISO时间戳}
```

异常退出时追加：
```
[ERROR]      {原因}，命令中止
```
