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

### 4. 读取 Context Checkpoint 与中断检测（核心）

**4a. 中断检测（优先执行）**

读取当前工作项的 `progress.md` **最后 25 条**结构化日志条目（每条条目以 `[TAG] ` 起始行为单元，如 `[START]`、`[COMPLETE]`、`[ERROR]` 等；取文件中末尾 25 个此类起始行对应的条目）。

检查末尾条目类型：
- 末尾为 `[COMPLETE]` → 正常结束，跳过恢复模式，继续步骤 4b
- 末尾为 `[ERROR]` 或其他非 `[COMPLETE]` 条目 → **进入恢复模式**
- `progress.md` 不存在或最后 25 条为空 → 跳过中断检测，继续步骤 4b

**恢复模式流程：**

1. 读取 `.devflow/work-items/{id}/checkpoints/` 下文件名格式为 `meta-{YYYYMMDDTHHmmSSZ}.json`（如 `meta-20260819T143022Z.json`），取文件名字典序最大的一份（即时间戳最新的快照）
2. 与当前 `meta.json` 对比 `status` 字段
3. 展示中断现场摘要：

```
⚠️  检测到异常中断

  工作项：{title}
  中断位置：{最后一条 [START] 对应的命令}（{时间戳}）
  最后操作：{最后一条非 [START]/[COMPLETE] 的条目内容}
  当前状态：{meta.json.status}
  上一稳定快照：{checkpoint 的 status}（{快照时间戳，从文件名 meta-{时间戳}Z.json 中提取，格式化为 YYYY-MM-DD HH:MM}）

  可选操作：
  1. 继续完成 devflow {command}（从当前状态恢复）
  2. 回滚到 {checkpoint status} 状态重新执行
  3. 查看完整中断日志（devflow audit --tail 25）

  选择 [1/2/3]：
```

选择处理逻辑：
- 选择 **1**：保持当前 meta.json 状态，继续步骤 4b；步骤 5 的状态机推荐以中断命令为准（如中断命令为 `devflow design`，则推荐「继续执行 `devflow design`」，不另外推荐其他命令）
- 选择 **2**：将 checkpoint 的 `meta-*.json` 内容覆写到 `meta.json`，告知用户「已回滚到 {status} 状态」，继续步骤 4b
- 选择 **3**：展示 `devflow audit --tail 25` 输出后重新展示三选项，等待用户再次选择
- checkpoints/ 目录不存在或为空时：跳过步骤 1-2，直接告知「未找到 checkpoint 快照，无法自动回滚，建议手动检查」，继续步骤 4b

**4b. 读取关键约束（Context Checkpoint 表格）**

中断检测完成（或用户完成选择）后，读取 `progress.md` 中的 Context Checkpoint 表格，快速恢复关键约束，避免重读所有长文档浪费 Token。

再补充读取 `meta.json` 获取状态和各阶段完成情况。

**读取 open-issues.md（若存在）：**

若工作项目录下存在 `open-issues.md`，检查 status=open 或 status=paused 的条目，在恢复上下文时优先展示：

```
⚠️ 开放问题（{n} 条 open/paused）：
   · OI-1：{问题描述摘要}（{类型}，{状态}）
   · OI-2：...
   （最多展示 3 条，超出说明总数）
   这些问题在继续推进前需要关注。
```

`open-issues.md` 不存在时静默跳过，不报错。

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
