---
name: devflow-list
description: DevFlow 工作项列表总览。展示所有活跃并行工作项（含 worktree 状态）和已完成项，可选同步 Meegle 状态。当用户说「查看工作项」「列出需求」「devflow list」时触发。
---

# devflow list — 查看工作项列表

**用途：** 展示所有工作项状态，重点呈现并行中的活跃工作项及其 worktree 状态，可选同步 Meegle 状态。

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

- 扫描 `.devflow/work-items/`，读取每个 `meta.json`
- 合并 `workspace.json.activeWorkItems` 中的 worktree / branch 信息
- 检查 worktree 目录是否实际存在（`git worktree list` 验证）

### 2. 分组展示

按以下三组组织：
- **Active**（并行进行中）：在 `activeWorkItems` 中的工作项
- **Paused**：有进度但不在 activeWorkItems 中
- **Completed**：`status = done`

**Epic 展示规则：**

`meta.json.isEpic = true` 的工作项在 Active 组前置展示，标注 `[EPIC]`，其 `childWorkItems` 缩进两格展示在下方：

```
[EPIC] 20260818-OptionDetailEpic   spec-only  ← Epic，无 worktree，无编码阶段
    └─ 20260818-DetailPageSwitch   coding    ✓ 依赖 Epic（已满足）
    └─ 20260818-PremarketChart     designing  ⚠️ sharedWith: DetailPageSwitch
```

`sharedWith` 不为空时，在子工作项行末展示 `⚠️ sharedWith: {其他工作项 slug}`，提示存在共享模块冲突风险。共享模块名从双方 `spec/design.md` 工程映射节提取（找不到则显示工作项 ID）。

### 3. 可选：同步 Meegle 状态

传入 `--sync` 时批量拉取：
```bash
meegle workitem batch-get --work-item-ids <ids> --fields '["name","status"]'
```

---

## 输出

```
DevFlow 工作项
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  活跃（{n} 个并行中）

  [*] 20260811-UserAvatarUpload   feature   coding
      Worktree：.worktrees/UserAvatarUpload  ✓ 存在
      Branch：feature/20260811-UserAvatarUpload
      Meegle：开发中

  [ ] 20260810-PaymentRefactor    tech      designing
      Worktree：.worktrees/PaymentRefactor   ✓ 存在
      Branch：feature/20260810-PaymentRefactor
      Meegle：需求确认

  [ ] 20260809-BugFix-LoginCrash  bug       planning
      Worktree：无（无 worktree）

  暂停
  [ ] 20260801-OldFeature         feature   analyzing   更新 5天前

  已完成
  [✓] 20260728-DarkMode           feature   done        更新 14天前
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合计：{n} 个（活跃 {a}，暂停 {p}，已完成 {c}）
[*] = 当前焦点

使用 `devflow switch` 切换焦点工作项
```
