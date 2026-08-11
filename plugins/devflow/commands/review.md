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

### 1. 查找专项 review skill

按以下路径顺序查找，找到第一个匹配即停止：

```
{项目根}/.claude/skills/
{项目根}/.ai/skills/
~/.claude/skills/
```

**已知专项 skill 名称：**

| Skill 名称 | 适用平台 | 判定特征 |
|-----------|---------|---------|
| `sahm-code-review-android` | Android / KMP Android 端 | `build.gradle` 中 apply 了 `com.android.application` / `com.android.library` / `kotlin-android`，**且**存在 `AndroidManifest.xml` |
| `sahm-code-review-ios` | iOS | 存在 `*.xcodeproj` / `*.xcworkspace` / `Podfile`，或 diff 含 `*.swift` / `*.m` / `*.h` |

**查找路径（按优先级，找到即停止）：**

```
{项目根}/.claude/skills/{skill-name}/skill.meta.md
{项目根}/.ai/skills/{skill-name}/skill.meta.md
~/.claude/skills/{skill-name}/skill.meta.md
/Users/apple/work/workflow/app-agent-assets/src/skills/{skill-name}/skill.meta.md
```

最后一条是团队共享路径，兜底使用。实际路径：
- Android：`/Users/apple/work/workflow/app-agent-assets/src/skills/sahm-code-review-android`
- iOS：`/Users/apple/work/workflow/app-agent-assets/src/skills/sahm-code-review-ios`

---

### 2A. 找到专项 skill → 委托执行

读取该 skill 目录下的 `skill.meta.md`，按其定义的规则执行完整审查：

- 加载 `skill.meta.md` 中的 `stack_detection`、`core_checklist`、`domain_hit_rules`
- 按 `domain_hit_rules` 扫描 diff，命中则加载对应 `references/domains/*.md`
- 按专项 checklist 逐条审查，输出分级报告（🔴 / 🟡 / 🟢）

审查结束后跳至步骤 4（影响面验证）。

---

### 2B. 未找到专项 skill → 通用四维度审查

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
