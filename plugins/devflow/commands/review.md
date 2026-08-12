---
name: devflow-review
description: DevFlow 代码审查阶段。优先委托项目配置的专项 review skill（如 sahm-code-review-android / sahm-code-review-ios），找不到时使用通用四维度审查。验证 CodeGraph 影响面一致性，可更新 Meegle 工作项状态。当用户说「代码审查」「review」「devflow review」或编码完成后需要审查代码质量时触发。
---

# devflow review — 代码审查

**用途：** 优先委托项目配置的专项 review skill 执行深度审查；找不到时降级到通用四维度审查。

---

## 前置条件

- `tasks.md` 中的任务应全部完成 `- [x]`（或用户明确说明只审查部分）。
- 代码可编译，基本测试通过。
- `meta.json` 状态为 `coding`（合法前驱）。

---

## 执行步骤

> **审查心智模型约束（所有步骤必须遵守）**
>
> 审查时必须模拟"第一次看这段代码的人"：不知道为什么这么改，不知道改了什么意图，只看代码本身是否正确。
> 对自己写的代码，"我知道为什么"是盲区的来源，不是审查通过的理由。

### 1. 查找专项 review skill

**第一优先级：读取项目配置**

从 `.devflow/workspace.json` 的 `reviewSkills` 字段读取已注册的专项 skill：

```json
// workspace.json 示例
{
  "reviewSkills": [
    {
      "name": "devflow-review-android",
      "triggerWhen": "diff 含 *.kt / *.java 且存在 AndroidManifest.xml",
      "path": ".ai/skills/devflow-review-android"
    },
    {
      "name": "devflow-review-frontend",
      "triggerWhen": "diff 含 *.vue 或 *.ts",
      "path": ".ai/skills/devflow-review-frontend"
    }
  ]
}
```

遍历 `reviewSkills` 列表，对当前 diff 逐条匹配 `triggerWhen` 描述的条件，**找到第一个匹配的 skill 后**：

1. 读取该条目 `path` 下的 `skill.meta.md`
2. 提取 `core_checklist` 作为主要审查清单
3. 提取 `domain_hit_rules`，扫描 diff 命中哪些领域规则，逐条加载
4. 按上述 checklist 逐条审查，输出分级报告（🔴 / 🟡 / 🟢）
5. 审查结束后跳至步骤 4（影响面验证）

**第二优先级：通用路径扫描（`reviewSkills` 为空或无匹配时）**

在以下路径中扫描所有包含 `skill.meta.md` 的目录，读取每个文件的 `stack_detection` 字段与当前 diff 特征对比，选出最匹配的：

```
{项目根}/.ai/skills/
{项目根}/.claude/skills/
~/.claude/skills/
```

找到匹配后，同样执行上述 1-5 步。

**两种方式都未找到匹配 → 降级到步骤 2B 通用四维度审查。**

> 如需配置专项 review skill，执行 `devflow init` 并选择"配置 Review Skill"。生成的规范文件在 `.ai/skills/devflow-review-{技术栈}/skill.meta.md`，可直接编辑自定义。

---

### 2B. 未找到专项 skill → 通用四维度审查

**❶ 退步检查（Regression Check）——必须第一个执行**

专门审查 diff 中**被删除的代码**，逐一确认每处删除的理由：

| 被删内容类型 | 必须回答的问题 |
|------------|-------------|
| 容器 / 布局组件（ScrollView、ConstraintLayout、SafeArea 等） | 删除后原有的滚动/约束/安全兜底能力是否仍有保障？ |
| 异常处理 / try-catch / fallback 分支 | 异常场景是否仍被覆盖？ |
| 资源释放 / 监听器注销 / 生命周期钩子 | 是否会引发泄漏？ |
| 校验逻辑 / 边界检查 | 边界情况是否仍受保护？ |

发现删除无法回答"仍有保障"的 → 标记 🔴 CRITICAL，不论当前视觉/功能是否正常。

**❷ 逐字符扫描（非语义扫描）**

字符串字面量、文案、注释必须**逐字符**审查，不得依赖语义记忆：
- 标点符号（句号后空格、全角/半角混用、省略号字符）
- 数字字面量（px/dp/sp 硬编码值）
- 颜色值、资源 ID 拼写

扫描时逐行朗读或逐字符比对，禁止"扫视"。

**❸ 严重程度保守原则**

评定等级时，必须问"在最坏的合理场景下会怎样"，而不是"在当前常见场景下是否正常"：

| 看起来是 Suggestion | 必须升级为 Warning 的条件 |
|--------------------|------------------------|
| 硬编码间距/字号 | 涉及大字体（无障碍）、多语言（文本长度变化）、不同屏幕密度 |
| 硬编码颜色 | 涉及深色模式 |
| 特定条件下视觉 OK | 该条件在用户实际使用中不能保证始终成立 |

凡涉及"系统性风险"（多语言/多主题/多字号/多屏幕）的 Suggestion，一律升级为 🟡 Warning。

**代码质量**
- 可读性与可维护性，命名规范
- 复杂函数是否有必要注释

**安全性**
- 认证绕过、越权访问
- 敏感数据暴露（密钥硬编码、日志泄露）

**性能**
- 内存泄漏（未清理的监听器、定时器、回调）
- 低效循环，重复计算

**反模式扫描**
读取 `bug-experience-cards.csv`，扫描本次提交代码是否命中已知高风险反模式。

---

### 3. CRITICAL 阻断门禁

发现以下任一问题时，输出 `BLOCKED` 状态，**必须阻止代码合并**：
- 安全漏洞（注入、越权、敏感数据暴露）
- 严重内存问题（循环引用、泄漏）
- 影响面超出设计预期且未确认
- **退步检查发现被删除的安全兜底（ScrollView/SafeArea/异常处理/校验逻辑）无替代保障**

---

### 4. CodeGraph 影响面一致性验证

```bash
devflow-cg impact <涉及符号>
```

将实际影响面与 `spec/design.md` 中「CodeGraph 爆炸半径评估」章节对比：
- 影响面收缩 → 正常
- 影响面扩大 → **发出警告**，要求开发者确认，写入 `review.md`

---

### 5. 生成审查报告

将审查结果写入 `review.md`，格式：

```
### Code Review Report

- **Skill**: {sahm-code-review-android v0.1.0 | sahm-code-review-ios v0.2.0 | 通用审查}
- **Status**: [APPROVED | CHANGES REQUESTED | BLOCKED]
- **Critical** 🔴: {n 条，必须修复后才能合并}
- **Warning** 🟡: {n 条，建议修复}
- **Info** 🟢: {n 条，可选优化}

详情：
  `{file}:{line}` 🔴 {问题描述}
  `{file}:{line}` 🟡 {问题描述}

- **影响面验证**: {一致 | 扩大（需确认）}
- **反模式命中**: {无 | n 处}
```

更新 `meta.json`：`status → reviewing`，`stages.reviewed = true`。

---

### 6. 触发强制复盘

若审查中发现需要沉淀的通用问题，自动生成经验卡草稿，提示执行 `devflow retrospect` 入库。

---

### 7. Worktree 合并与 MR（审查通过时）

若 `meta.json.worktree` 存在（编码阶段在 worktree 中进行），审查通过（Status: APPROVED）后，按 `finishing-a-development-branch` skill 的流程处理：

```
实现已完成，代码审查通过。请选择后续操作：

1. 合并到本地 <base-branch>
2. Push 并创建 MR/PR
3. 保留分支（稍后自行处理）
4. 丢弃此次改动
```

**选择「2. Push 并创建 MR/PR」时**：
```bash
# Push 分支
git push -u origin feature/{YYYYMMDD}-{slug}

# 创建 MR（GitLab）或 PR（GitHub）
gh pr create \
  --title "{工作项标题}" \
  --body "$(cat <<'EOF'
## 改动说明
- {来自 spec/requirement.md 的功能点}

## 涉及文件
{来自 tasks.md 的文件清单}

## 验收清单
- [ ] {来自 spec/acceptance-checklist.md，若已生成}

## Meegle 工作项
{linkedMeegleId 链接}
EOF
)"
```

**选择「1. 合并到本地」时**：
```bash
git checkout <base-branch> && git pull
git merge feature/{YYYYMMDD}-{slug}
git worktree remove .worktrees/{slug}
git branch -d feature/{YYYYMMDD}-{slug}
# 从 workspace.json.activeWorkItems 中移除该工作项，更新 focus 为下一个活跃项（若有）
```

**选择「3. 保留分支」时**：保留 worktree，不执行任何 git 操作。

**Status 为 CHANGES REQUESTED 或 BLOCKED 时**：不触发此步骤，开发者修复问题后重新执行 `devflow review`。

---

### 8. 可选：更新 Meegle 状态

若 `meta.json.linkedMeegleId` 存在且审查通过：
```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
meegle comment add --work-item-id <id> \
  --content "✅ 代码审查通过\n\nSkill: {skill名称}\nCritical: 0\nWarning: {n}"
```

---

## 输出

```
### Code Review Report
- Skill: {sahm-code-review-android v0.1.0 | 通用审查}
- Status: [APPROVED | CHANGES REQUESTED | BLOCKED]
- Critical 🔴: {n}
- Warning  🟡: {n}
- Info     🟢: {n}
- 影响面验证: {一致 | 扩大（需确认）}
- Worktree: {feature/YYYYMMDD-slug → 等待选择合并方式 | 无 worktree}

Meegle 状态：{已流转 | 未配置}

下一步：使用 `devflow retrospect` 沉淀本次开发经验。
```
