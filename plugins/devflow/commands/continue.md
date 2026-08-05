---
name: devflow-continue
description: DevFlow 进度恢复。新会话或 /clear 后读取 Context Checkpoint 快速恢复上下文，根据状态机推荐下一步。当用户说「恢复进度」「继续开发」「devflow continue」或打开新会话需要接续上次工作时触发。
---

# devflow continue — 恢复进度

**用途：** 新会话或 `/clear` 后，优先读取 Context Checkpoint 快速恢复上下文，根据状态机推荐下一步，展示 Meegle 最新状态。

---

## 前置条件

- `.devflow/` 目录存在。

---

## 执行步骤

### 1. 检查 workspace

读取 `.devflow/workspace.json`：

- 文件不存在 → 提示用户先执行 `devflow init` 或 `devflow start`
- `currentWorkItem` 为空 → 提示执行 `devflow list` 查看工作项或 `devflow switch` 切换

### 2. 多工作项并发冲突检查

扫描 `work-items/` 下所有 `meta.json`，若存在多个 `status` 为 `coding` 或 `planning` 的工作项：
```
⚠️ 检测到多个活跃工作项：
  [1] {id-slug}（状态：coding）
  [2] {id-slug}（状态：planning）
请选择要继续的工作项编号：
```
等待用户选择，不自行决定。

### 3. 读取 Context Checkpoint（核心）

**优先读取 `progress.md` 中的 Checkpoint 表格**，快速恢复关键约束，避免重读所有长文档浪费 Token。

再补充读取 `meta.json` 获取状态和各阶段完成情况。

### 4. 状态机推荐

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

### 5. 可选：同步 Meegle 最新状态

若 `meta.json.linkedMeegleId` 存在，拉取 Meegle 工作项最新状态展示（不主动流转）：
```bash
meegle workitem get --work-item-id <id> --fields '["name","status","priority"]'
```

---

## 输出

```
当前工作项：{title}（{id}-{slug}）
本地状态：{当前阶段}
Meegle 状态：{状态 | 未配置}

Context Checkpoint（上次记录）：
{checkpoint 内容摘要}

已完成阶段：{analyze ✓} {design ✓} {plan ...}

推荐下一步：`devflow {command}`
{若处于 coding 阶段，显示下一个未完成任务摘要}

请问想要继续还是其他操作？
```
