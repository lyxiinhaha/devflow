# DevFlow × Meegle 集成参考

本文档说明 DevFlow 各命令中调用 Meegle CLI 的具体方式，供命令实现时参考。

> Meegle CLI 完整文档参见 `meegle` skill。

---

## 授权检查

每次调用前先验证授权状态：

```bash
meegle auth status
```

- 若已授权：继续执行
- 若未授权：提示 `meegle auth login`，完成后执行 `meegle user me` 验证

---

## 常用操作速查

### 获取当前用户

```bash
meegle user me
```

### 搜索项目空间

```bash
meegle project search --project-key <空间名称或 projectKey>
```

返回 `project_key`，写入 `workspace.json`。

---

## devflow start — 创建工作项

```bash
# 1. 获取工作项类型
meegle workitem meta-types --project-key <key>

# 2. 获取字段配置（含模板 ID）
meegle workitem meta-fields \
  --project-key <key> \
  --work-item-type <type_key>

# 3. 创建工作项
meegle workitem create \
  --work-item-type <type_key> \
  --project-key <key> \
  --fields '[{"field_key":"name","field_value":"<标题>"},{"field_key":"template","field_value":"<template_id>"},{"field_key":"description","field_value":"<描述>"}]'
```

将返回的 `work_item_id` 写入 `meta.json.linkedMeegleId`。

---

## devflow analyze — 添加需求分析评论

```bash
meegle comment add \
  --work-item-id <linkedMeegleId> \
  --content "📋 需求分析完成\n\n**背景**：...\n**验收标准**：...\n\n> 由 DevFlow 自动同步"
```

---

## devflow fix — 读取 Bug 详情

```bash
meegle workitem get \
  --work-item-id <id> \
  --fields '["name","description","priority","status"]'
```

修复完成后流转状态：

```bash
# 查询可流转状态
meegle workflow list-state-transitions --work-item-id <id>

# 流转（选择「已修复」对应的 transition_id）
meegle workflow transition-state \
  --work-item-id <id> \
  --transition-id <transition_id>

# 添加修复说明
meegle comment add \
  --work-item-id <id> \
  --content "🔧 修复完成\n\n**根因**：...\n**修改文件**：...\n**验证方式**：..."
```

---

## devflow code — 流转至「开发中」

```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
```

---

## devflow estimate — 更新排期

```bash
# 获取节点信息
meegle workflow get-node \
  --work-item-id <id> \
  --node-id-list '["_all"]'

# 更新排期（时间为毫秒时间戳）
meegle workflow update-node \
  --work-item-id <id> \
  --node-id <node_key> \
  --node-schedule '{"estimate_start_date":1722182400000,"estimate_end_date":1722614400000}'
```

---

## devflow review — 流转至「待合并」并添加审查报告

```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>

meegle comment add \
  --work-item-id <id> \
  --content "✅ 代码审查通过\n\n**影响面**：一致\n**反模式检查**：无"
```

---

## devflow retrospect — 关闭工作项

```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
```

---

## devflow list — 批量查询状态

```bash
meegle workitem batch-get \
  --work-item-ids <id1>,<id2>,<id3> \
  --fields '["name","status"]'
```

---

## devflow change — 更新工作项描述

```bash
# 获取字段 key
meegle workitem meta-fields --project-key <key> --work-item-type <type> --field-query description

# 更新描述（追加变更内容）
meegle workitem update \
  --work-item-id <id> \
  --fields '[{"field_key":"description","field_value":"<原描述>\n\n---\n**变更记录 {日期}**：..."}]'

# 添加变更评论
meegle comment add \
  --work-item-id <id> \
  --content "🔄 需求变更\n\n{变更描述}"
```

---

## 字段值格式提醒

所有 `field_value` 均为字符串协议（STRING）：
- 数组/对象必须先 `JSON.stringify` 后传入
- 多用户字段：`"[\"userkey1\",\"userkey2\"]"`
- 日期字段：毫秒时间戳字符串，如 `"1722182400000"`

详见 `meegle` skill 的「字段值格式」章节。
