# DevFlow 易用性增强设计规格

> 设计日期：2026-08-20
> 范围：devflow doctor 诊断命令、devflow tour 向导命令、devflow start 新用户感知、README 快速上手路径

---

## 背景与目标

DevFlow 当前的核心易用性问题：20 个命令 + 大量专有概念，新用户不知道从哪里开始。本设计通过三个新增/改动提供明确的「入门路径」：

1. **`devflow doctor`**：随时可调用的环境诊断工具，两级输出 + 一键修复
2. **`devflow tour`**：向导式新手命令，带用户用真实需求走完关键路径
3. **`devflow start` 新用户感知**：首次使用时自动提示导览入口
4. **README 3 行上手框**：文档层面的最短路径

---

## 一、`devflow doctor` 诊断命令

### 调用方式

```bash
devflow doctor          # 全量检查（默认）
devflow doctor --fix    # 检查 + 对 🔴 必须修复项自动执行修复命令
devflow doctor --quick  # 仅检查 🔴 必须修复项，跳过 🟡 建议修复
```

### 检查项分级

**🔴 必须修复（阻塞正常使用）**

| 检查项 | 检测方式 | 修复命令 |
|--------|---------|---------|
| `.devflow/` 目录存在且 workspace.json 完整 | 检查文件存在 + currentWorkItem / techStack / codegraph 节点 | `devflow init` |
| CodeGraph 已安装 | `codegraph --version` | `npm install -g @colbymchenry/codegraph` |
| `bug-experience-cards.csv` 存在 | 检查文件路径 | 从模板复制 |
| `knowledge-usage.jsonl` 存在 | 检查文件路径 | 从模板复制 |

**🟡 建议修复（影响体验但不阻塞）**

| 检查项 | 检测方式 | 修复建议 |
|--------|---------|---------|
| Hook 脚本存在且可执行 | `ls -x .devflow/hooks/devflow-audit.sh` | `devflow init`（步骤 6.5） |
| Hook 已注册到 settings.json | 检查 `.claude/settings.json` 中 hooks 字段 | `devflow init` |
| Meegle 已授权 | `meegle auth status` | `meegle auth login` |
| YApi 可达（若已配置） | `curl -s --max-time 3 https://{yapiHost}/api/user/status` | 检查 yapiHost 配置或网络 |
| CodeGraph 索引新鲜 | 比较 `.codegraph/codegraph.db` mtime 与项目文件最新 mtime | `codegraph index` |

### 输出格式

```
DevFlow Doctor — 环境诊断
─────────────────────────────────────────────────
🔴 必须修复（2 项）
  ✗ .devflow/ 目录不存在
    → 修复：devflow init
  ✗ CodeGraph 未安装
    → 修复：npm install -g @colbymchenry/codegraph

🟡 建议修复（1 项）
  ⚠ Hook 未注册（audit / state-guard 不生效）
    → 修复：重新执行 devflow init，选择 Claude Code 平台

✅ 通过（3 项）
  ✓ workspace.json 完整
  ✓ Meegle 已授权（用户：{username}）
  ✓ CodeGraph 索引新鲜（最后更新：{n} 小时前）

总结：2 项必须修复，1 项建议修复。
运行 `devflow doctor --fix` 自动修复必须项。
```

无问题时输出：
```
✅ DevFlow 环境一切正常，可以开始使用。
```

### `--fix` 模式

对每个 🔴 项逐一确认执行：

```
即将自动修复 {n} 项：
  1. 执行 devflow init（建立 .devflow/ 目录）
  2. 执行 npm install -g @colbymchenry/codegraph

继续？[y/N]
```

用户确认后逐项执行，每项执行后报告结果。

---

## 二、`devflow tour` 向导命令

### 定位

向导式新手命令，带用户用真实（或示例）需求走完 start → analyze → design 三个关键阶段，每步都有说明。`devflow tour` 的每个阶段调用与独立命令完全一致的逻辑，不是演示，是真实执行。

### 调用方式

```bash
devflow tour          # 启动向导
devflow tour --skip   # 跳过环境预检直接进入向导
```

任何时候 Ctrl+C 退出，向导保留已创建的工作项，下次可用 `devflow continue` 恢复。

### 向导流程

#### 步骤 0：环境预检

自动运行 `devflow doctor --quick`，有 🔴 项时暂停：

```
⚠️  发现环境问题，tour 可能无法正常运行：
   ✗ CodeGraph 未安装 → npm install -g @colbymchenry/codegraph

选择：1. 先修复再继续  2. 忽略继续（部分功能不可用）  3. 退出
```

无问题时静默通过。

#### 步骤 1：说明 + 选择需求

```
👋 欢迎使用 DevFlow！

DevFlow 把一个需求的完整开发过程拆成 8 个阶段：
  需求分析 → 技术设计 → 任务拆解 → 编码 → 代码评审 → 经验沉淀

接下来你将用一个需求走完前 3 个阶段，大约 10 分钟。

你有一个需求想练手，还是用一个示例需求？
  1. 用我自己的需求（直接描述即可）
  2. 用示例需求（「给用户列表页增加搜索过滤功能」）
```

#### 步骤 2：创建工作项

```
📝 第 1 阶段：创建工作项

DevFlow 的每个需求都是一个「工作项」，存储在 .devflow/work-items/ 里。
状态机会追踪它从创建到完成的每一步。

[执行 devflow start feature {需求标题}]

✅ 工作项已创建：{workItemId}
   目录：.devflow/work-items/{id}/
   
💡 这个目录会存放需求文档、设计方案、任务清单，是 AI 的「工作台」。
```

#### 步骤 3：需求分析

```
🔍 第 2 阶段：需求分析

把你的需求告诉我，我来帮你识别功能点、发现歧义、关联接口。
可以是文字描述，也可以粘贴 Figma 链接或接口文档。

[进入 Intake Mode，与 devflow analyze 行为完全一致]

✅ 需求分析完成！
   生成文件：spec/requirement.md
   
💡 这份文档是后续所有阶段的基础。
   遇到需求变化时，用 devflow change 触发变更流程，不要直接修改文档。
```

#### 步骤 4：技术设计

```
🏗️  第 3 阶段：技术设计

我来分析现有代码结构，制定改动方案，评估影响范围。

[执行 devflow design，行为与独立调用完全一致]

✅ 技术设计完成！
   生成文件：spec/design.md
   
💡 设计文档冻结后，编码阶段不能随意修改。
   发现设计有问题时，用 devflow change 触发变更。
```

#### 步骤 5：完成 & 下一步引导

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

## 三、`devflow start` 新用户感知

### 触发条件（同时满足）

1. `.devflow/work-items/` 目录为空或不存在
2. `workspace.json.tourPromptCount` < 3（或字段不存在）
3. 用户未传入 `--no-guide` 参数

### 引导提示

```
检测到这是你的第一个工作项。
建议先运行 devflow tour 获得完整的向导体验（约 10 分钟）。

直接继续创建工作项，还是先做个导览？
1. 继续创建（跳过导览）
2. 先运行 devflow tour

选择 [1/2，默认 1，5 秒后自动选 1]：
```

- 选择 2 → 转入 `devflow tour` 流程
- 选择 1 或超时 → 正常执行 `devflow start`，命令末尾追加一条提示：

```
✅ 工作项已创建。
💡 遇到问题可运行 devflow doctor 检查环境，或 devflow tour 获取向导。
```

### 计数更新

每次展示引导提示后，`workspace.json.tourPromptCount += 1`。达到 3 次后不再显示，避免打扰。

---

## 四、README 快速上手

在 README「快速开始」章节最顶部新增 3 行上手框：

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

> 遇到问题随时运行 `devflow doctor` 诊断环境。
> 熟悉后直接用 `devflow start` 创建你的第一个需求。
```

---

## 五、命令改动清单

| 文件 | 操作 | 改动量 |
|------|------|--------|
| `commands/doctor.md` | 新建 | ~80 行 |
| `commands/tour.md` | 新建 | ~120 行 |
| `commands/start.md` | 修改：新增新用户感知逻辑 | +20 行 |
| `README.md` | 修改：快速开始章节前追加上手框 | +15 行 |

---

*规格版本：v1.0 | 覆盖范围：易用性增强（doctor + tour + start 感知 + README）*
