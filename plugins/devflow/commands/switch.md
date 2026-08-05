---
name: devflow-switch
description: DevFlow 切换当前活跃工作项。更新 workspace，自动恢复新工作项上下文。当用户说「切换需求」「切换工作项」「devflow switch」或需要从一个需求切换到另一个需求时触发。
---

# devflow switch — 切换工作项

**用途：** 保存当前工作项状态后，切换到另一个工作项，自动恢复新工作项的 Context Checkpoint。

---

## 前置条件

- `workspace.json` 存在。
- `.devflow/work-items/` 目录存在且有至少一个工作项。

---

## 执行步骤

### 1. 保存当前状态

切换前确认当前工作项的 `tasks.md` 进度已反映最新状态（任务完成情况已标记），`progress.md` 已更新。

若有未保存的状态变化，提示用户确认是否继续切换。

### 2. 列出所有工作项

扫描 `work-items/`，读取每个 `meta.json`，展示列表（当前活跃项用 `[*]` 标记）：

```
DevFlow 工作项
─────────────────────────────────────────
  [*] {id}-{slug}    {type}    {status}    ← 当前
  [ ] {id}-{slug}    {type}    {status}
  [✓] {id}-{slug}    {type}    done
─────────────────────────────────────────
请输入要切换的工作项编号或 ID：
```

### 3. 目标校验

- 目标工作项不存在 → **报错并终止**，不得猜测或模糊匹配：
  ```
  ✗ 工作项 {input} 不存在。请从上方列表选择有效的工作项。
  ```
- 目标即当前工作项 → 提示无需切换

### 4. 更新 workspace

将 `workspace.json` 中的 `currentWorkItem` 更新为目标工作项 ID。

### 5. 恢复上下文

自动执行 `devflow continue` 逻辑，读取新工作项的 Context Checkpoint 并展示推荐下一步。

---

## 输出

```
### Switched Workspace
- **Previous**: {id}-{slug}（Paused）
- **Current**: {id}-{slug}（{status}）

{自动执行 devflow continue 的输出}
```
