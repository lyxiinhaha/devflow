---
name: devflow-switch
description: DevFlow 切换焦点工作项。在多个并行工作项之间切换当前会话焦点，不影响其他活跃工作项的 worktree 和进度。当用户说「切换需求」「切换工作项」「devflow switch」时触发。
---

# devflow switch — 切换焦点

**用途：** 在并行的多个工作项之间切换当前会话的焦点（`focus`），不影响其他工作项的 worktree、分支和进度。

---

## 前置条件

- `workspace.json` 存在。
- `activeWorkItems` 中至少有一个工作项。

---

## 执行步骤

### 1. 保存当前状态

切换前确认当前工作项的 `tasks.md` 进度已标记，`progress.md` 已更新。

### 2. 展示所有工作项

扫描 `work-items/`，合并 `workspace.json.activeWorkItems` 的状态，展示完整列表：

```
所有工作项
─────────────────────────────────────────────────────
  活跃（并行中）
  [*] 20260811-UserAvatarUpload   coding    .worktrees/UserAvatarUpload   ← 当前焦点
  [ ] 20260810-PaymentRefactor    designing  .worktrees/PaymentRefactor
  [ ] 20260809-BugFix-LoginCrash  planning   （无 worktree）

  已完成
  [✓] 20260801-DarkMode           done
─────────────────────────────────────────────────────
输入编号切换焦点，或输入工作项 ID：
```

### 3. 目标校验

目标工作项不在列表中 → 报错终止，不猜测。

### 4. 更新 focus（仅更新焦点，不影响其他活跃项）

```json
{ "focus": "{target-id}" }
```

**不改变** `activeWorkItems` 中其他工作项的状态、worktree、分支。

### 5. 恢复目标工作项上下文

自动执行 `devflow continue` 逻辑，读取新焦点的 Context Checkpoint 并展示推荐下一步。

---

## 输出

```
### Switched Focus
- 上一个焦点：{id-slug}（已保留 worktree：{path | 无}）
- 当前焦点：{id-slug}（{status}，worktree：{path | 无}）

{自动执行 devflow continue 的输出}
```
