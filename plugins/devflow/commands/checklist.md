---
name: devflow-checklist
description: DevFlow 生成真机验收清单。基于当前工作项的需求文档和技术方案，生成结构化的真机测试清单，包含进入路径、前提条件、Mock 数据、逐条检查点和回归验证表。当用户说「验收清单」「测试清单」「QA checklist」「devflow checklist」或需要为本次改动生成测试用例时触发。
---

# devflow checklist — 生成真机验收清单

**用途：** 基于 `spec/requirement.md`（验收标准）和 `spec/design.md`（涉及模块），生成可交付给测试人员的结构化真机验收清单，尤其针对有前端页面的功能。

---

## 前置条件

- `spec/requirement.md` 存在，且包含验收标准章节。
- 建议 `spec/design.md` 也已生成（可提供更准确的涉及模块和数据结构）。

---

## 查找专项 checklist skill

在执行前，先检查项目是否配置了专项 checklist skill：

```
{项目根}/.claude/skills/project-acceptance-checklist/SKILL.md
{项目根}/.ai/skills/project-acceptance-checklist/SKILL.md
~/.claude/skills/project-acceptance-checklist/SKILL.md
```

**找到专项 skill** → 读取其 SKILL.md，按其规范生成清单（包含 Mock 接口表格格式等项目特有约定），本命令的通用规则作为补充。

**未找到** → 按以下通用规则生成。

---

## 执行步骤

### 1. 读取需求和方案

从以下来源提取信息：

- `spec/requirement.md`：功能需求、验收标准（AC 编号）、用户故事
- `spec/design.md`：涉及模块、接口依赖、数据模型
- `spec/tech-design-doc.md`：接口清单（路径 + 字段）、功能流程说明

### 2. 判断是否涉及前端页面

检测以下信号词（出现任一即视为有前端页面改动）：

页面 / 弹窗 / 底部面板 / 列表 / 按钮 / 文案 / 图标 / 导航 / Tab / 跳转 / 样式 / 布局 / UI

有前端页面 → 必须包含**进入路径**和**UI 检查点**。

无前端页面（纯逻辑/接口/配置变更）→ 跳过进入路径，聚焦数据检查和状态验证。

### 3. 识别前提条件复杂度

对每个验收点，判断其前提条件是否需要 Mock：

| 情况 | 处理 |
|------|------|
| 特定账号状态难以真实构造（特定 applyStatus、权限、到期时间等） | **必须提供 Mock 接口和字段** |
| 依赖后端/后台尚未上线的字段或配置 | 标注「需 XX 先上线/配置后才可用真实环境验证」，并提供 Mock |
| 真实账号可轻松满足 | 直接说明账号需具备的条件 |

### 4. 生成清单

每个功能点按以下结构输出：

````markdown
### {功能名称}（对应 AC 编号）

**前提条件**
- 账号/数据条件（具体到字段值，如 `status=3`、`renewable=true`）
- 依赖项（后端/后台是否需要先上线或配置）

**进入路径**（有前端页面时必填）
> 从首页或主 Tab 出发，用 → 分隔每步操作
> 如有多条路径，全部列出

**Mock 接口**（前提条件难以真实构造时必填）
| 接口路径 | 字段名 | Mock 值 | 说明 |
|---------|--------|---------|------|
| /xxx/yyy | field | "value" | 说明 |

**检查点**
- ✅ AC-XX：{具体可观测的 UI 状态或行为，不写「正确展示」这类模糊表述}
- ❌ 旧行为（仅改动类需要）：~~{旧的错误展示}~~

**边界 / 异常**
- {边界条件} → {预期结果}
- 网络异常 → {兜底展示}
- 空数据 → {空态展示}
````

### 5. 回归验证表

每份清单末尾附**回归验证表**，列出本次改动可能影响的现有功能：

```markdown
### 回归验证

| 检查项 | 进入路径 | 预期（不受影响的行为） |
|--------|---------|----------------------|
| {现有功能点} | {路径} | {预期行为} |
```

识别方式：
- 从 `devflow-cg impact <涉及符号>` 的结果中找出被影响的现有模块
- 结合 `bug-experience-cards.csv` 中该模块的历史 Bug，判断回归风险点

### 6. 输出清单文件

将生成的清单写入：

```
.devflow/work-items/{id}-{slug}/spec/acceptance-checklist.md
```

**若当前工作项在 worktree 中编码（`meta.json.worktree` 存在）**，在清单头部加上 worktree 路径信息，方便用其他编辑器打开调试：

```markdown
## 调试环境

| 项 | 路径 |
|----|------|
| Worktree | `{项目根}/{worktree路径}`（如 `/Users/xxx/proj/.worktrees/UserAvatarUpload`） |
| 分支 | `{branch}`（如 `feature/20260812-UserAvatarUpload`） |
| 直接打开 | `open {项目根}/{worktree路径}` |

> 在此 worktree 目录下直接用 Xcode / Android Studio / VS Code 打开即可，环境已初始化。
```

同时在对话中完整输出，方便直接复制给测试人员。

---

## 检查点写法规范

**✅ 好的写法（具体可观测）：**
- `✅ AC-01：页面标题显示「修改密码」，字号 16sp，居中对齐`
- `✅ AC-02：输入框 placeholder 文案为「请输入 6-20 位密码」`
- `✅ AC-03：提交按钮在密码少于 6 位时置灰不可点击`

**❌ 坏的写法（模糊，无法验证）：**
- `✅ 页面正确显示`
- `✅ 按钮功能正常`
- `✅ 数据展示正确`

**多语言 / 暗夜模式（如需求涉及）：**
- 英文、繁体中文分别验证文案
- Light / Dark 两种主题下的 UI 截图对比

---

## 输出

```
✅ 验收清单已生成

  Skill: {project-acceptance-checklist | 通用规范}
  功能点: {n} 个
  需要 Mock 的场景: {n} 个
  有前端页面: {是 | 否}
  回归验证项: {n} 条
  Worktree: {绝对路径 | 无 worktree}

  已写入: spec/acceptance-checklist.md
```
