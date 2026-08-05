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
