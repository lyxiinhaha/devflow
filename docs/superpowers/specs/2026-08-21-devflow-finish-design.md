# devflow finish 设计规格

**版本：** v1.0  
**日期：** 2026-08-21  
**状态：** 已确认，待实现

---

## 背景与问题

DevFlow 的 worktree 生命周期目前存在断层：
- `devflow code` 创建 worktree（`git worktree add`）
- worktree 的销毁逻辑内嵌在 `review.md` 步骤 7，超过 200 行，且引用了外部 `finishing-a-development-branch` skill
- 若用户在 review 时选择"保留分支"，后续没有标准命令来完成收尾

**目标：** 新增 `devflow finish` 命令，作为 worktree 生命周期的标准终点，替换 `review.md` 步骤 7 的内嵌逻辑，完成分支合并/推送和 workspace 状态清理。

---

## 方案选型

**精简替换**：`devflow finish` 专注呈现四个选项（本地合并 / Push+PR / 保留 / 丢弃），执行选择并完成 workspace 清理。`review.md` 步骤 7 替换为引导用户调用 `devflow finish` 的简短提示。

---

## 一、命令概述与触发条件

### 合法前驱状态

| 状态 | 行为 |
|---|---|
| `reviewing`（review 通过，retrospect 尚未执行） | 允许，但在呈现选项前输出建议提示 |
| `done`（retrospect 已完成） | 直接进入主流程，无额外提示 |

reviewing 状态时的提示：
```
ℹ️  建议先执行 devflow retrospect 沉淀本次经验，再完成收尾。
   如需跳过，继续即可。
```

### 非法状态处理

```
✗ 状态机拦截：当前状态 [{status}] 不允许执行 devflow finish。
  合法前驱状态：reviewing、done
```

### 无 worktree 时

`meta.json.worktree` 为空（用 `devflow code noworktree` 编码）→ 跳过所有 git 操作，仅执行 workspace 状态清理。

---

## 二、执行步骤

### 1. 前置检查

读取 `workspace.json.focus` 确定当前工作项，读取该工作项 `meta.json`：
- 状态不合法 → 报错并中止
- `meta.json.worktree` 为空 → 标记"无 worktree 模式"，跳过步骤 2

### 2. 呈现选项（有 worktree 时）

```
DevFlow Finish — {workItemId}
Worktree：{meta.json.worktree}   Branch：{meta.json.branch}
──────────────────────────────────────
如何处理这个分支？

1. 本地合并到 {base-branch}
2. Push 并创建 PR / MR
3. 保留分支（稍后处理）
4. 丢弃本次工作
```

`base-branch` 从 `git symbolic-ref refs/remotes/origin/HEAD` 推导，默认为 `main`。

### 3. 执行选择

**选项 1：本地合并**

```bash
git checkout {base-branch} && git pull
git merge {branch}
git worktree remove {worktree-path}
git branch -d {branch}
```

合并失败（冲突）时输出：
```
✗ 合并冲突，请手动解决后执行 git worktree remove {worktree-path} && git branch -d {branch}
```

完成后执行步骤 4（workspace 清理）。

**选项 2：Push + PR/MR**

```bash
git push -u origin {branch}
```

平台判断：
- 存在 `.github/` 目录或 `gh` 命令可用 → 使用 `gh pr create`
- 存在 `.gitlab-ci.yml` 或 `glab` 命令可用 → 使用 `glab mr create`
- 两者均不可用 → 仅 push，提示用户手动创建 PR/MR

Worktree **保留**（不执行 worktree remove）。完成后执行步骤 4（workspace 清理）。

**选项 3：保留分支**

不执行任何 git 操作，不清理 worktree。输出：
```
保留分支 {branch}，worktree 位于 {worktree-path}。
下次运行 devflow finish 可继续处理。
```

**跳过步骤 4**（workspace 状态不变）。

**选项 4：丢弃**

先输出确认提示：
```
⚠️  即将丢弃以下内容：
   Branch：{branch}
   Commits：{git log --oneline {base-branch}..{branch} 的输出}
   Worktree：{worktree-path}

   输入 discard 确认，其他任意输入取消：
```

等待用户输入 `discard`（精确匹配）后执行：

```bash
git worktree remove {worktree-path} --force
git branch -D {branch}
```

完成后执行步骤 4（workspace 清理）。

### 4. Workspace 清理（选项 1、2、4 完成后；选项 3 跳过）

1. 从 `workspace.json.activeWorkItems` 中移除当前工作项
2. 若 `workspace.json.focus` 等于当前工作项 ID，将 `focus` 置空
3. 将 `meta.json.worktree` 和 `meta.json.branch` 设为 `null`
4. 若 `meta.json.linkedMeegleId` 存在，询问是否更新 Meegle 节点状态（非强制）

### 5. 输出收尾摘要

```
✅ devflow finish 完成

  工作项：{title}
  操作：{合并到 main | 已推送，PR 地址 {url} | 已丢弃}
  Worktree：{已清理 | 已保留}
```

---

## 三、review.md 步骤 7 变更

将现有步骤 7 的 200+ 行内嵌逻辑替换为：

```markdown
### 7. Worktree 收尾

若 `meta.json.worktree` 存在（编码阶段在 worktree 中进行），审查通过后输出：

```
✅ 审查通过。下一步：
   执行 devflow retrospect 沉淀经验，
   再执行 devflow finish 完成分支收尾。
```

若无 worktree，输出审查通过摘要，无需后续 git 操作。
```

---

## 四、执行日志规范

```
[START]      {ISO时间戳} devflow finish
[DECISION]   选择 {1/2/3/4}：{选项说明，如"本地合并到 main"}
[WRITE]      workspace.json (activeWorkItems 移除 {workItemId})
[WRITE]      .devflow/work-items/{workItemId}/meta.json (worktree/branch 清空)
[COMPLETE]   devflow finish — {ISO时间戳}
```

异常退出时：
```
[ERROR]      {原因}，命令中止
```

---

## 五、影响面

**新增文件：**
- `plugins/devflow/commands/finish.md`

**修改文件：**
- `plugins/devflow/commands/review.md`（步骤 7 替换为简短引用）
- `plugins/devflow/commands/README.md`（新增 finish 命令条目）
