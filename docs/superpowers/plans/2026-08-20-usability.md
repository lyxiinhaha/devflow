# DevFlow 易用性增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `devflow doctor`（环境诊断）和 `devflow tour`（向导命令），增强 `devflow start` 的新用户感知，并在 README 添加 3 行上手路径。

**Architecture:** 全部改动为 Markdown AI 指令文件（新建 / 修改），不引入新依赖。doctor 和 tour 是独立新命令；start.md 在步骤 1 之后插入新用户感知逻辑；README 在「快速开始」章节顶部添加极简上手框。

**Tech Stack:** Markdown（AI instruction files）

**规格文档：** `docs/superpowers/specs/2026-08-20-usability-design.md`

---

## 文件结构

| 路径 | 操作 | 职责 |
|------|------|------|
| `plugins/devflow/commands/doctor.md` | 新建 | 环境诊断命令：两级检查 + --fix 修复模式 |
| `plugins/devflow/commands/tour.md` | 新建 | 向导命令：5 步带用户走完 start→analyze→design |
| `plugins/devflow/commands/start.md` | 修改 | 步骤 1 后插入步骤 1.5：新用户感知 + 引导提示 |
| `README.md` | 修改 | 「快速开始」章节顶部追加 3 行上手框 |

---

## Task 1：新建 commands/doctor.md

**Files:**
- Create: `plugins/devflow/commands/doctor.md`

- [ ] **Step 1：写入完整文件内容**

写入 `plugins/devflow/commands/doctor.md`：

```markdown
---
name: devflow-doctor
description: DevFlow 环境诊断。检查 DevFlow 运行所需的环境完整性和连通性，输出两级问题清单（🔴 必须修复 / 🟡 建议修复），每项附带修复命令。当用户说「检查环境」「环境诊断」「devflow doctor」或遇到 DevFlow 无法正常使用时触发。
---

# devflow doctor — 环境诊断

**用途：** 一键检查 DevFlow 运行环境，输出两级问题清单，支持 `--fix` 自动修复必须项。

---

## 调用方式

```
devflow doctor          # 全量检查（默认）
devflow doctor --fix    # 检查 + 对 🔴 必须修复项逐一确认后自动执行修复命令
devflow doctor --quick  # 仅检查 🔴 必须修复项，跳过 🟡 建议修复
```

---

## 检查项

### 🔴 必须修复（阻塞正常使用）

按顺序逐项检查，发现问题继续检查剩余项（不中断）：

| 检查项 | 检测方式 | 修复命令 |
|--------|---------|---------|
| `.devflow/workspace.json` 存在 | 检查文件是否存在 | `devflow init` |
| `workspace.json` 字段完整 | 检查 `techStack`、`codegraph` 节点存在 | `devflow init`（重新初始化） |
| CodeGraph 已安装 | 执行 `codegraph --version`，命令不存在则标记失败 | `npm install -g @colbymchenry/codegraph` |
| `bug-experience-cards.csv` 存在 | 检查 `.devflow/config/templates/knowledge/bug-experience-cards.csv` | 从插件模板目录复制 |
| `knowledge-usage.jsonl` 存在 | 检查 `.devflow/config/templates/knowledge/knowledge-usage.jsonl` | 从插件模板目录复制 |

### 🟡 建议修复（影响体验但不阻塞）

| 检查项 | 检测方式 | 修复建议 |
|--------|---------|---------|
| Hook 脚本存在且可执行 | 检查 `.devflow/hooks/devflow-audit.sh` 存在且有执行权限 | 重新执行 `devflow init` |
| Hook 已注册到 settings.json | 读取 `.claude/settings.json`，检查 `hooks.PostToolUse` 和 `hooks.PreToolUse` 字段 | 重新执行 `devflow init`（Claude Code 平台） |
| Meegle 已授权 | 执行 `meegle auth status`，命令不存在或未授权则标记警告 | `meegle auth login` |
| YApi 可达（若已配置） | 读取 `workspace.json.integrations.yapiHost`；若存在，执行 `curl -s --max-time 3 https://{yapiHost}/api/user/status`，失败则警告 | 检查 yapiHost 配置或网络连接 |
| CodeGraph 索引新鲜 | 若 `.codegraph/codegraph.db` 存在，比较其 mtime 与 `workspace.json.codegraph.roots` 下文件的最新 mtime；db 比源文件旧超过 24 小时则警告 | `codegraph index` |

---

## 执行逻辑

### 默认模式 / `--quick` 模式

逐项执行检查，收集所有结果，最终一次性输出报告。

`--quick` 模式跳过所有 🟡 项，只执行 🔴 项。

### 输出格式

```
DevFlow Doctor — 环境诊断
─────────────────────────────────────────────────
🔴 必须修复（{n} 项）
  ✗ {检查项名称}
    → 修复：{修复命令}

🟡 建议修复（{n} 项）
  ⚠ {检查项名称}
    → 修复：{修复建议}

✅ 通过（{n} 项）
  ✓ {检查项名称}（{可选补充信息，如：用户 yixin.liu / 最后更新 2小时前}）

总结：{n} 项必须修复，{n} 项建议修复。
运行 `devflow doctor --fix` 自动修复必须项。
```

全部通过时输出：
```
✅ DevFlow 环境一切正常，可以开始使用。
```

### `--fix` 模式

对所有 🔴 项展示将要执行的修复命令列表，等待用户确认后逐项执行：

```
即将自动修复 {n} 项：
  1. {修复命令 1}
  2. {修复命令 2}

继续？[y/N]
```

用户确认后逐项执行，每项输出执行结果（成功 ✅ / 失败 ✗ + 错误信息）。

---

## 前置条件

- 在项目根目录执行（需要能访问 `.devflow/`、`.claude/` 等目录）
- 无其他前置依赖，即使 DevFlow 未初始化也可运行（这是诊断命令的核心价值）
```

- [ ] **Step 2：验证文件格式正确**

```bash
head -5 plugins/devflow/commands/doctor.md
grep -c "devflow-doctor" plugins/devflow/commands/doctor.md
grep -c "🔴\|🟡\|--fix\|--quick" plugins/devflow/commands/doctor.md
```

期望：第一行为 `---`，第二条返回 `1`，第三条返回 `3` 或更多。

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/doctor.md
git commit -m "feat(usability): 新增 devflow doctor 环境诊断命令"
```

---

## Task 2：新建 commands/tour.md

**Files:**
- Create: `plugins/devflow/commands/tour.md`

- [ ] **Step 1：写入完整文件内容**

写入 `plugins/devflow/commands/tour.md`：

```markdown
---
name: devflow-tour
description: DevFlow 向导命令。带新用户用真实需求走完 start → analyze → design 三个关键阶段，每步都有说明。当用户说「新手向导」「导览」「devflow tour」或首次使用 DevFlow 时触发。
---

# devflow tour — 新手向导

**用途：** 带用户用一个真实（或示例）需求走完 start → analyze → design 三个关键阶段，每步都有解释。tour 的每个阶段与独立调用对应命令完全一致，不是演示，是真实执行。

---

## 调用方式

```
devflow tour          # 启动向导（含环境预检）
devflow tour --skip   # 跳过环境预检，直接进入向导
```

任何时候 Ctrl+C 退出，已创建的工作项会保留，下次可用 `devflow continue` 恢复。

---

## 执行流程

### 步骤 0：环境预检

自动运行 `devflow doctor --quick`，检查 🔴 必须修复项。

**发现问题时：**
```
⚠️  发现环境问题，tour 可能无法正常运行：
   ✗ {问题描述} → {修复命令}

选择：
1. 先修复再继续
2. 忽略继续（部分功能不可用）
3. 退出
```

无问题时静默通过，直接进入步骤 1。

`devflow tour --skip` 时跳过本步骤。

---

### 步骤 1：欢迎说明 + 选择需求

```
👋 欢迎使用 DevFlow！

DevFlow 把一个需求的完整开发过程拆成 8 个阶段：
  需求分析 → 技术设计 → 任务拆解 → 编码 → 代码评审 → 经验沉淀

接下来你将用一个需求走完前 3 个阶段，大约 10 分钟。

你有一个需求想练手，还是用一个示例需求？
  1. 用我自己的需求（直接描述即可）
  2. 用示例需求（「给用户列表页增加搜索过滤功能」）
```

选择 2 时，使用「给用户列表页增加搜索过滤功能」作为后续需求内容，并在每步说明中标注「（示例）」。

---

### 步骤 2：创建工作项（调用 devflow start 逻辑）

```
📝 第 1 阶段：创建工作项

DevFlow 的每个需求都是一个「工作项」，存储在 .devflow/work-items/ 里。
状态机追踪它从创建到完成的每一步。

[执行 devflow start feature {需求标题}，行为与独立调用完全一致]

✅ 工作项已创建：{workItemId}
   目录：.devflow/work-items/{id}/

💡 这个目录会存放需求文档、设计方案、任务清单，是 AI 的「工作台」。
   你随时可以用 devflow list 查看所有工作项。
```

---

### 步骤 3：需求分析（调用 devflow analyze 逻辑）

```
🔍 第 2 阶段：需求分析

把你的需求告诉我，我来帮你识别功能点、发现歧义、关联接口。
可以是文字描述，也可以粘贴 Figma 链接或接口文档。

[进入 devflow analyze 的 Intake Mode，行为与独立调用完全一致]

✅ 需求分析完成！
   生成文件：spec/requirement.md

💡 这份文档是后续所有阶段的基础。
   遇到需求变化时，用 devflow change 触发变更流程，不要直接修改文档。
```

---

### 步骤 4：技术设计（调用 devflow design 逻辑）

```
🏗️  第 3 阶段：技术设计

我来分析现有代码结构，制定改动方案，评估影响范围。

[执行 devflow design，行为与独立调用完全一致]

✅ 技术设计完成！
   生成文件：spec/design.md

💡 设计文档冻结后，编码阶段不能随意修改。
   发现设计问题时，用 devflow change 触发变更，不要直接编辑 design.md。
```

---

### 步骤 5：完成 & 下一步引导

```
🎉 恭喜完成 DevFlow 导览！

工作项：{title}（{workItemId}）
已完成：创建工作项 ✅  需求分析 ✅  技术设计 ✅

下一步：
  devflow plan   ← 把设计拆成可执行任务清单
  devflow code   ← 按任务清单开始编码

随时可用：
  devflow list     ← 查看所有工作项
  devflow doctor   ← 检查环境状态
  devflow audit    ← 查看操作历史
  devflow continue ← 恢复上次中断的工作
```

---

## 禁令

- ❌ 步骤 0 的环境预检结果不得影响后续步骤的正常执行逻辑（环境问题只提示，不强制中断向导）
- ❌ 步骤 2/3/4 的执行逻辑必须与对应独立命令保持完全一致，不得简化或跳步
- ❌ 不得自动跳过用户交互（每步都需要用户实际参与）
```

- [ ] **Step 2：验证文件格式正确**

```bash
head -5 plugins/devflow/commands/tour.md
grep -c "devflow-tour" plugins/devflow/commands/tour.md
grep -n "步骤 0\|步骤 1\|步骤 2\|步骤 3\|步骤 4\|步骤 5" plugins/devflow/commands/tour.md
```

期望：第一行为 `---`，第二条返回 `1`，第三条输出 6 行。

- [ ] **Step 3：提交**

```bash
git add plugins/devflow/commands/tour.md
git commit -m "feat(usability): 新增 devflow tour 新手向导命令"
```

---

## Task 3：更新 commands/start.md — 新用户感知

**Files:**
- Modify: `plugins/devflow/commands/start.md`

- [ ] **Step 1：找到步骤 1 结束位置**

```bash
grep -n "### 1\. 前置检查\|### 2\. 解析输入" plugins/devflow/commands/start.md
```

期望输出类似：
```
35:### 1. 前置检查与自愈
39:### 2. 解析输入
```

- [ ] **Step 2：在「### 2. 解析输入」标题正前方插入步骤 1.5**

找到 `### 2. 解析输入` 这行，在其**正前方**插入：

```markdown
### 1.5 新用户感知（首次使用引导）

检查以下条件是否**同时满足**：
1. `.devflow/work-items/` 目录为空或不存在
2. `workspace.json.tourPromptCount` < 3（字段不存在时视为 0）
3. `$ARGUMENTS` 不含 `--no-guide`

三个条件同时满足时，展示以下提示并等待选择：

```
检测到这是你的第一个工作项。
建议先运行 devflow tour 获得完整的向导体验（约 10 分钟）。

直接继续创建工作项，还是先做个导览？
1. 继续创建（跳过导览）
2. 先运行 devflow tour

选择 [1/2，默认 1，5 秒后自动选 1]：
```

**选择处理逻辑：**
- 选择 **2**：将 `workspace.json.tourPromptCount += 1`，然后转入 `devflow tour` 流程，不继续执行 start 后续步骤
- 选择 **1** 或超时：将 `workspace.json.tourPromptCount += 1`，正常继续步骤 2；命令末尾（步骤 6 之后）追加一条提示：
  ```
  💡 遇到问题可运行 devflow doctor 检查环境，或 devflow tour 获取向导。
  ```

条件不满足时（老用户、计数已达 3、传入 --no-guide）：静默跳过本步骤，直接进入步骤 2。

```

- [ ] **Step 3：验证插入位置正确**

```bash
grep -n "1.5 新用户感知\|tourPromptCount\|### 2\. 解析输入" plugins/devflow/commands/start.md
```

期望：步骤 1.5 的行号小于步骤 2 的行号，`tourPromptCount` 在同一区域出现。

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/commands/start.md
git commit -m "feat(usability): start 新增步骤 1.5 新用户感知和引导提示"
```

---

## Task 4：更新 README.md — 快速上手框

**Files:**
- Modify: `README.md`

- [ ] **Step 1：找到「快速开始」章节位置**

```bash
grep -n "## 快速开始\|### 前置依赖" README.md
```

期望类似：
```
219:## 快速开始
221:### 前置依赖
```

- [ ] **Step 2：在「## 快速开始」之后、「### 前置依赖」之前插入上手框**

找到 `### 前置依赖` 这行，在其**正前方**插入：

```markdown
## ⚡ 3 行命令上手

```bash
# 1. 安装（Claude Code）
claude plugins install devflow

# 2. 检查环境
devflow doctor

# 3. 开始向导
devflow tour
```

> 遇到问题随时运行 `devflow doctor` 诊断环境。熟悉后直接用 `devflow start` 创建你的第一个需求。

---

```

- [ ] **Step 3：验证插入位置和内容**

```bash
grep -n "3 行命令上手\|devflow doctor\|devflow tour\|### 前置依赖" README.md | head -10
```

期望：「3 行命令上手」的行号小于「前置依赖」的行号，`devflow doctor` 和 `devflow tour` 均出现在上手框区域。

- [ ] **Step 4：提交**

```bash
git add README.md
git commit -m "docs(usability): README 快速开始章节新增 3 行上手框"
```

---

## 自检结果

**规格覆盖检查：**

| 规格章节 | 对应任务 | 覆盖 |
|---------|---------|------|
| 一、devflow doctor（调用方式/检查项/输出格式/--fix 模式） | Task 1 | ✅ |
| 二、devflow tour（5 步流程/环境预检/下一步引导） | Task 2 | ✅ |
| 三、devflow start 新用户感知（触发条件/引导提示/计数/--no-guide） | Task 3 | ✅ |
| 四、README 快速上手框 | Task 4 | ✅ |
| 五、命令改动清单 | 全部任务 | ✅ |

**占位符扫描：** 无 TBD / TODO。所有命令文件包含完整内容。

**类型一致性：** `tourPromptCount` 字段名在 Task 3（start.md）中使用，与规格第三节定义一致。`devflow doctor --quick` 在 Task 2（tour.md 步骤 0）中调用，与 Task 1（doctor.md 调用方式）定义一致。
