---
name: devflow-list
description: DevFlow 工作项列表总览。列出所有本地工作项状态，可选同步展示 Meegle 状态。当用户说「查看工作项」「列出需求」「devflow list」或想了解当前有哪些进行中的需求时触发。
---

# devflow list — 查看工作项列表

**用途：** 按状态分组展示所有工作项，输出完整字段（ID / 标题 / 类型 / 状态 / 优先级 / 最后更新时间），可选同步 Meegle 最新状态。

---

## 前置条件

- `workspace.json` 存在。

不满足时输出：
```
No work items found. 请先执行 devflow start 创建工作项。
```

---

## 执行步骤

### 1. 读取所有工作项

扫描 `.devflow/work-items/`，读取每个 `meta.json`，提取：
- ID（`{YYYYMMDD}-{slug}`）
- 标题（`title`）
- 类型（`type`）
- 状态（`status`）
- 优先级（`priority`）
- 最后更新时间（`updatedAt`）
- Meegle ID（`linkedMeegleId`，若有）

### 2. 按状态分组

按以下三组组织：
- **Active**：status 为 `created / analyzing / designing / planning / estimating / coding / reviewing`
- **Paused**（当前非 active 且未完成）：保留但不活跃的工作项
- **Completed**：status 为 `done`

若某分组无工作项，显示 `None`。

### 3. 可选：同步 Meegle 状态

若传入 `--sync` 参数，且存在 `linkedMeegleId` 的工作项，批量拉取 Meegle 状态：
```bash
meegle workitem batch-get \
  --work-item-ids <id1>,<id2> \
  --fields '["name","status"]'
```

---

## 输出

```
### Project Workspaces

#### Active (n)
- **[*]** {YYYYMMDD}-{slug}  {type}  {status}  P{priority}  更新 2h 前  Meegle: {状态|未关联}

#### Paused (n)
- **[ ]** {YYYYMMDD}-{slug}  {type}  paused    P{priority}  更新 2天 前

#### Completed (n)
- **[✓]** {YYYYMMDD}-{slug}  {type}  done      P{priority}  更新 5天 前

─────────────────────────────────────────
总计：{n} 个工作项（Active: {a}，Completed: {c}）
使用 `devflow switch` 切换工作项
```
