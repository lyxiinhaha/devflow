---
name: devflow-continue
description: DevFlow 进度恢复。新会话或 /clear 后读取 Context Checkpoint 快速恢复上下文，支持多工作项并行，展示所有活跃 worktree 状态。当用户说「恢复进度」「继续开发」「devflow continue」或打开新会话需要接续上次工作时触发。
---

# devflow continue — 恢复进度

**用途：** 新会话或 `/clear` 后，读取 Context Checkpoint 快速恢复上下文，支持多工作项并行工作，根据状态机推荐下一步。

---

## 前置条件

- `.devflow/` 目录存在。

---

## 执行步骤

### 1. 检查 workspace

读取 `.devflow/workspace.json`：

- 文件不存在 → 提示用户先执行 `devflow init` 或 `devflow start`
- `focus` 和 `activeWorkItems` 均为空 → 提示执行 `devflow list` 或 `devflow start`

### 2. 展示所有活跃工作项

读取 `workspace.json.activeWorkItems`，展示并行中的所有工作项：

```
活跃工作项（{n} 个并行中）：

  [*] 20260811-UserAvatarUpload   coding    .worktrees/UserAvatarUpload   ← 当前焦点
  [ ] 20260810-PaymentRefactor    designing  .worktrees/PaymentRefactor
  [ ] 20260809-BugFix-LoginCrash  planning   （无 worktree）
```

`[*]` 表示当前 `focus` 指向的工作项。多工作项时询问：

```
当前焦点：{title}。是否继续，还是切换到其他工作项？
1. 继续 {focus 工作项}
2. 切换焦点（列出其他活跃项）
```

若只有一个活跃项，直接恢复，不询问。

### 3. CodeGraph 索引新鲜度检查

若 `workspace.json.codegraph.roots` 存在，对每个 root 快速检查：

```bash
stat -f "%m" Podfile.lock vs stat -f "%m" .codegraph/codegraph.db
```

发现过期时给出提醒（不阻塞流程）：
- iOS：Podfile.lock 比 db 新 → `⚠️ 建议执行 devflow-cg index`
- Android：submodule 有新 commit → `⚠️ 建议执行 devflow-cg index`
- 本地 Pod 有变更 → `⚠️ 建议执行 devflow-cg sync`

### 4. 读取 Context Checkpoint（核心）

**优先读取 `progress.md` 中的 Checkpoint 表格**，快速恢复关键约束，避免重读所有长文档浪费 Token。

再补充读取 `meta.json` 获取状态和各阶段完成情况。

### 5. 状态机推荐

根据 `devflow.json` 的状态转换配置推荐下一步：

| 当前状态 | 推荐命令 |
|---------|---------|
| `created` | `devflow analyze` |
| `analyzing` | `devflow design` |
| `designing` | `devflow estimate` 或 `devflow plan` |
| `planning` | `devflow code` |
| `estimating` | `devflow plan` |
| `coding` | 读取 `tasks.md`，找到第一个 `- [ ]` 任务，显示任务详情后提示 `devflow code` |
| `reviewing` | `devflow retrospect` |
| `done` | 工作项已完成，可执行 `devflow switch` 切换 |

若工作项有 `worktree` 字段，展示 worktree 路径和当前 branch。

### 6. 可选：同步 Meegle 最新状态

若 `meta.json.linkedMeegleId` 存在，拉取 Meegle 工作项最新状态展示（不主动流转）：
```bash
meegle workitem get --work-item-id <id> --fields '["name","status","priority"]'
```

---

## 输出

```
活跃工作项：{n} 个并行中

[*] 当前焦点：{title}（{id}-{slug}）
    状态：{当前阶段}    Worktree：{路径 | 无}    Branch：{branch | 无}
    Meegle：{状态 | 未配置}

    Context Checkpoint（上次记录）：
    {checkpoint 内容摘要}

    已完成阶段：{analyze ✓} {design ✓} {plan ...}
    推荐下一步：`devflow {command}`

[ ] {其他活跃项1}  {状态}  {worktree路径}
[ ] {其他活跃项2}  {状态}  （无 worktree）

请问想要继续还是其他操作？
```
