---
name: devflow-code
description: DevFlow 编码执行阶段。默认在独立 worktree 中编码（隔离改动，review 后直接提 MR），传入 noworktree 参数跳过。包含 CodeGraph 主动预警、前置检查门禁、L0 安全限制。当用户说「开始编码」「执行编码」「devflow code」或需要按任务清单实现代码时触发。
---

# devflow code — 执行编码

**用途：** 依据已冻结的设计文档和任务清单逐项编码，包含 CodeGraph 主动预警、前置检查门禁、质量门禁，完成后可更新 Meegle 状态。

---

## 前置条件

- `spec/design.md` 存在且已冻结。
- `tasks.md` 存在且含未完成任务 `- [ ]`。
- `workspace.json` 存在且状态 active。
- `meta.json` 状态为 `planning` / `estimating`（合法前驱）。

不满足时输出：
```
✗ 缺少任务清单或所有任务已完成。
  请先执行 devflow plan 进行任务拆解。
```

---

## ⚠️ 编码禁令（Coding Prohibitions）

1. **❌ 禁止越界修改**：不得修改当前任务范围外的文件，即使发现"顺手"的改进机会。
2. **❌ 禁止修改设计文档**：编码阶段不得修改 `spec/design.md` 或 `spec/api.md`；发现设计问题必须停止编码，触发 `devflow change`。
3. **❌ 禁止未批准的重构**：不得重构任务中未明确指定的代码。
4. **❌ 禁止盲目执行**：任务描述有歧义时，必须停下来询问用户，不得自行假设继续。
5. **❌ L0 模块**：标注 `🔒 [人工审查必须]` 的任务，只提供代码建议片段，禁止直接写入文件。

---

## 执行步骤

### 1. 创建 Worktree

**默认行为：在独立 worktree 中编码。** 传入 `noworktree` 参数时跳过。

```
devflow code              ← 默认，创建 worktree
devflow code noworktree   ← 跳过 worktree，在当前工作区直接编码
```

**创建流程：**

```bash
# 检查 worktree 目录（优先级：.worktrees/ > worktrees/ > 使用 .worktrees/）
ls -d .worktrees 2>/dev/null || ls -d worktrees 2>/dev/null

# 确认目录在 .gitignore 中（不在则先添加并 commit）
git check-ignore -q .worktrees

# 创建 worktree
git worktree add .worktrees/{slug} -b feature/{YYYYMMDD}-{slug}

# 自动初始化 worktree 环境（软链本地文件、iOS 执行 pod install）
bash <devflow-skill-dir>/devflow-worktree-setup/worktree-setup.sh .worktrees/{slug}
```

脚本自动处理：
- **Android**：软链 `local.properties`（SDK 路径）到 worktree，`gradlew` 直接可用
- **iOS**：检查 path Pod 路径，执行 `pod install`，worktree 可直接 Xcode 打开运行

Worktree 路径写入 `meta.json`，同时注册到 `workspace.json.activeWorkItems`：
```json
{
  "focus": "{YYYYMMDD}-{slug}",
  "activeWorkItems": [
    {
      "id": "{YYYYMMDD}-{slug}",
      "title": "{title}",
      "status": "coding",
      "worktree": ".worktrees/{slug}",
      "branch": "feature/{YYYYMMDD}-{slug}",
      "startedAt": "{ISO时间戳}"
    }
  ]
}
```

已有其他活跃工作项时，追加到 `activeWorkItems` 数组，不覆盖。

---

### 2. 执行范围确认

读取 `tasks.md`，展示未完成任务摘要，询问用户本次执行范围（除非用户已明确指定）：

```
当前还有以下未完成任务：
1. [T001] {任务标题}
2. [T002] {任务标题}

请选择本次执行范围：
1. 只完成第一个未完成任务
2. 完成所有未完成任务（遇到阻塞性问题才停止）
3. 执行到指定编号任务（请回复任务编号）
```

### 3. Context Checkpoint 恢复

从 `progress.md` 读取 Checkpoint，防止长会话遗忘关键约束。

### 4. CodeGraph 主动预警

```bash
devflow-cg status   # 检查索引新鲜度，pod update / submodule 更新后自动提示重建
```

若编码期间检测到其他分支/协作者引入了对当前修改符号的新调用，**必须主动提示用户重新评估影响面**，不得静默继续。

### 5. 任务执行循环

对每个待执行任务：

**a) L0 安全检查**
标注 `🔒 [人工审查必须]` → 仅提供代码片段建议，禁止写入文件。

**b) CodeGraph 现有实现探查（复用优先）**

编码前先查，**禁止在未探查的情况下直接新建类/方法**：

从任务的 `Description` 和 `Files` 中提取关键词（类名、方法名、功能动词、业务实体），执行：
```bash
devflow-cg explore "<关键词 空格分隔>"
```
codegraph_explore("<关键词 空格分隔>")
```

按结果决定实现策略：

| 探查结果 | 策略 |
|---------|------|
| 找到完全匹配的现有实现 | **直接复用**，在任务描述中记录复用的类/方法路径 |
| 找到部分匹配（逻辑相似但不完全一致） | **改造复用**，说明改造点，不重复造轮子 |
| 未找到相关实现 | **新建**，在 `spec/design.md` 指定的架构层级内创建 |

探查结论写入任务完成记录（`progress.md`）：
```
[T001] 已完成
  复用策略：{直接复用 XxxRepository.fetchData() | 改造 XxxManager | 新建 YyyComponent}
  文件：{实际修改的文件路径}
```

**c) CodeGraph 前置检查门禁**
标注 `⚠️ [CodeGraph 前置检查]` → 必须执行：
```bash
devflow-cg explore <涉及符号>
devflow-cg impact  <涉及符号>
```
- HIGH / CRITICAL → **强制暂停**，等待用户确认后才能继续
- 用户拒绝确认 → 标记任务为「等待确认」，跳过该任务

**d) 编码实现**
- 只修改任务 `Files` 字段中指定的文件
- 参照 `spec/design.md` 和 `spec/requirement.md` 实现
- 遵守任务 `Technical Requirements` 中的编码约束
- **优先调用步骤 b 中探查到的现有工具方法/组件**，不重复实现已有逻辑

**e) 质量门禁**
编码完成后执行：
- Lint 检查（如 `eslint` / `ktlint` / `swiftlint`，按项目配置）
- 已有测试命令（如 `./gradlew :module:test`）
- 记录 lint/test 结果

**f) 状态同步**
立即将任务标记为 `- [x]`，不得批量完成后再统一标记。

### 6. Context Checkpoint 更新

将本轮完成的任务摘要追加写入 `progress.md`。

所有任务完成后更新 `meta.json`：`status → coding`，`stages.coded = true`。

### 7. 可选：更新 Meegle 状态

若 `meta.json.linkedMeegleId` 存在且所有任务已完成，询问是否流转 Meegle 状态：
```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
```

---

## 输出（每完成一个任务）

```
### Task Completed: [T001]
- **Files Modified**: `src/index.js`, `src/utils.js`
- **Lint/Test Status**: Passed
- **Next Step**: 继续 [T002] 或结束编码阶段
```

## 汇总输出（所有任务完成）

```
✅ 编码完成。
  完成任务：{n} 个
  CodeGraph 前置检查：{n} 次
  高风险暂停确认：{n} 次
  L0 仅建议（未直接写入）：{n} 处
  Lint/Test：{通过 | 失败项见下方}
  Meegle 状态：{已流转至「{状态}」 | 未配置}

下一步：使用 `devflow review` 进行代码审查。
```
