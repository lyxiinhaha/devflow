---
name: devflow-fix
description: DevFlow Bug 修复专用流程。支持 Meegle issue 链接/ID/视图批量处理，三阶段 CodeGraph 分析，90 分评分门禁，最小修复原则，人工验证门禁，强制复盘。当用户说「修复 bug」「fix」「devflow fix」，或提供 project.feishu.cn 链接时触发。
---

# devflow fix — Bug 修复

**用途：** DevFlow 专用 Bug 修复流程。支持 Meegle issue 链接/ID/视图批量处理，三阶段 CodeGraph 分析，90 分评分门禁，最小修复原则，独立会话隔离，人工验证门禁，修复后强制复盘。

---

## 输入

通过 `$ARGUMENTS` 传入，支持三种格式：
- `https://project.feishu.cn/...` — Meegle issue 详情页或视图/列表链接（推荐）
- Meegle 工作项纯数字 ID（如 `12345678`）
- 直接描述 Bug 现象（不关联 Meegle）

---

## 执行模式判定

在读取 issue 之前先判断本次执行模式：

| 模式 | 判断条件 | 行为 |
|------|---------|------|
| **分析模式** | 提示词不含 `修复`/`fix`/`解决`/`改代码` | 只做分析，不改业务代码 |
| **修复模式** | 提示词明确含修复意图 | 分析 + 最小修复 + 生成清单 + **等待人工验证** |
| **重排查模式** | 含 `重开`/`验证不通过`/`还有问题`/`仍然失败`/`二次排查`/`再看看`，或 Meegle issue 状态为「已重开」 | 历史清单 + 调试日志 + **提交前必须清除日志** |

---

## Step 0：输入门禁

### URL 门禁

若输入为 URL，只接受：
```
https://project.feishu.cn
```
其他域名：生成失败分析文件，结束整批。

### URL 解析与批量队列

使用 `meegle` skill 的 `url decode` 解析 URL，根据 `url_kind` 分支：

- **`workitem_detail`**：单条 issue，直接进入 Step 1。
- **`view / issueView / filter`**：视图/列表，必须枚举全部 bug 条目（翻页至 `has_more = false`），为每条拼接独立详情 URL，建立 Bug 队列。**禁止**将批量视图 URL 作为单条的 Bug 链接。

批量时创建批次目录 `.bugfix-records/<yyMMdd>/` 及 `batch-summary.md`（队列 ≥ 2 条时必须维护）。

### DevFlow 工作项创建

为每条 Bug 在 `.devflow/work-items/` 下创建工作项：
```
.devflow/work-items/{YYYYMMDD}-{bugSlug}/
├── meta.json          ← type=bug, status=created, linkedMeegleId=<id>
├── context/
│   ├── raw.md         ← Meegle issue 原始内容（AI 禁止直接读取）
│   └── sanitized.md
├── spec/requirement.md
├── tasks.md
└── progress.md
```

---

## Step 1：读取 Issue 详情

使用 `meegle` skill：
```bash
meegle workitem get --work-item-id <id> --fields '["_all"]'  # 翻页取全部字段
meegle comment list --work-item-id <id>                       # 获取全部评论
# 若有附件，通过 attachment 命令下载
```

- Meegle 授权失败 → 提示 `meegle auth login`，同一 issue 最多重试 3 次；超出则生成失败分析文件，继续下一条。
- 将读取内容写入 `context/raw.md`（**AI 后续只读 sanitized.md**）。

### 信息完整性校验

**必须项**（缺一则进入失败路径）：
- 仓库地址与分支名称
- Bug 现象描述
- 预期描述（修复后应有的行为）

**参考项**（缺失不失败，降低置信度，需注明）：
- 复现步骤
- 截图 / 附件内容
- 日志、评论、接口事实

**仓库与分支来源优先级（高→低）：**
1. 用户本次提示按 bug 单独指定
2. 用户本次提示全局统一指定
3. Meegle issue 字段中的仓库/分支信息
4. 当前工作区（`git remote get-url origin` + `git branch --show-current`）

当前工作区 remote URL 与目标一致、且分支名一致时**强制复用**，不新建 worktree。

---

## Step 2：根因分析（三阶段 CodeGraph 法）

### 调用 ①：定位入口符号
```
codegraph_explore("<关键类名、方法名或自然语言描述>")
```
返回相关符号逐行源码、文件路径、调用关系；结果已等效于 Read，可直接据此 Edit。

### 调用 ②：爆炸半径门禁
```
codegraph_explore("<根因方法名> 调用方 影响")
```

| 直接调用方 | 风险等级 | 行为 |
|------------|------|------|
| 0–2 | LOW | 继续 |
| 3–10 | MEDIUM | 列出受影响模块 |
| 11–30 | HIGH | **暂停，等待用户确认** |
| 30+ | CRITICAL | **强制拦截**，要求提交专项重构方案 |

### 调用 ③：修复后影响面验证
```
codegraph_explore("<修改后符号> 影响")
```
**强制断言**：影响面不得扩大。若扩大，报错并要求修复后重新验证。

CodeGraph 不可用时：降级 grep/find + Read，分析文件中注明。

### 分析评分（修复准入门禁）

对每个 Bug 的分析结论评分（0–100）：

| 维度 | 权重 |
|------|------|
| 信息完整性（仓库/分支/现象/预期） | 20 |
| 根因定位质量（有代码证据） | 30 |
| 修复方案质量（最小、安全、可执行） | 25 |
| 影响范围与风险说明 | 15 |
| 验证方案可执行性 | 10 |

**评分等级：** 90–100 A / 80–89 B / 70–79 C / <70 F

**修复准入门禁：只有总分 ≥ 90（A 级）才允许进入修复模式。**

评分 < 90 时：
```
✗ 评分 {score}/100，低于修复准入门禁（90分）。
  拒绝进入修复模式。需要补充：
  - {缺失的关键信息或分析缺口}
```

---

## Step 3：执行修复（修复模式，评分 ≥ 90 才执行）

**修复原则：**
- 最小改动，只修当前 bug 所需内容
- 不引入新抽象、新依赖
- 遵守项目代码规范（`CLAUDE.md` / `AGENTS.md`）
- **修复完成后不执行 `git commit`**

修复后：
1. 运行编译验证（如 `./gradlew :<module>:compileDebugKotlin`），记录结果
2. 展示 `git diff` 供人工 review
3. 生成 Bug 修复清单文件（Step 4）

**批量时隔离规则：** 同仓同分支的多条 bug 顺序修复；每条 bug 开始前确认上一条的修改已暂存且 `git status` 为 clean，不跨 bug 混入修改。不同 bug 应在独立修复会话或等价隔离 worker 中执行，避免上下文污染。

---

## Step 3.5：重排查流程（仅重排查模式）

替代 Step 3 的直接修复逻辑。

### 1. 读取历史修复清单
在 `.bugfix-records/` 下查找该 issue 最新一份清单，提取上次根因、修复方案摘要和验证失败现象。未找到 → 按首次修复模式处理，注明「首次处理，历史记录缺失」。

### 2. 分析失效原因
重新追踪调用链，重点关注：是否遗漏触发路径、是否有条件遗漏（边界值/时序/竞态）、数据来源层是否仍有错误值。

### 3. 添加调试日志
使用项目已有日志框架（`Timber.d` / `Log.d` / `HSLog.d`），tag 统一加前缀 `[BUGFIX_<issue_id>]`，每个 bug 日志点 ≤ 10 处：
```kotlin
// [BUGFIX_<issue_id>] 临时排查日志，验证后删除
Timber.d("[BUGFIX_<issue_id>] varName=%s", varValue)
```

输出排查指引，等待用户提供日志后再进入实际修复。

### 4. 日志清理（提交前强制）
用户确认排查完成后：
1. **先删除所有带 `[BUGFIX_<issue_id>]` 的日志行**
2. 编译验证
3. 在清单「重排查记录」章节记录日志结论和根因修正

**强制约束：** 提交前执行 `grep -rn "BUGFIX_<issue_id>"` 确认零残留，有残留则**拒绝提交**。

---

## Step 4：生成 Bug 修复清单

每个 bug 在以下路径生成独立清单文件：
```
.bugfix-records/<yyMMdd>/<issue_id>-<bug简述>-bug修复清单.md
```

### 清单格式

```markdown
# Bug 修复清单

## 基本信息
| 字段 | 内容 |
|---|---|
| Bug 链接 | <issue 详情页 URL> |
| Issue ID | <issue_id> |
| DevFlow 工作项 | <work-item-id> |
| 修复时间 | <YYYY-MM-DD> |
| 修复人 | <git user.name> |
| 分支 | <branch> |
| 状态 | 待人工验证 |
| 评分 | <score>/100（A级，已通过准入门禁）|

## Bug 描述
<现象 + 触发场景>

## 影响范围
- **模块**：
- **严重程度**：
- **复现概率**：
- **直接调用方**：

## 问题原因
**根因文件**：`<file_path>:<line_number>`
```{语言}
// 修改前关键代码（上下文各 2-3 行）
```

## 解决方案
**修改文件**：`<file_path>`
```{语言}
// 修改后关键代码
```
**修改说明**：

## 验证方法
**编译验证**：`<命令>` → <结果>
**人工验收步骤**：
1. ...
**回归场景**：
- ...

## 修复总结
因为 <根因> 导致 <影响范围>，采用 <修复方案> 修复，风险等级为 <低/中/高>。

## 重排查记录（仅重排查模式）
...

## 提交信息（待人工验证后执行）
```
fix: <bug 标题或短描述> #<issue_id>
```
```

---

## Step 5：等待人工验证

所有 bug 处理完成后，输出汇总并**等待确认，不执行任何 git 操作**：

```
✅ 本轮修复已完成，等待人工验证后逐条提交。

── 修复摘要 ─────────────────────────────────────
[1] #<issue_id> <标题>
    评分：<score>/100（A级）
    文件：<file_path>
    变更：<一句话描述>
    清单：.bugfix-records/<yyMMdd>/<issue_id>-bug修复清单.md

── 验证建议 ─────────────────────────────────────
[1] <验收步骤摘要>

确认每条验证通过后，请告知「第 N 条验证通过」或「全部验证通过」。
```

---

## Step 6：收到验证通过后提交

### 提交前检查
1. **重排查模式强制**（其他模式建议）：
   ```bash
   grep -rn "BUGFIX_<issue_id>" <仓库目录>
   ```
   有输出 → **拒绝提交**，提示删除残留日志。
2. 确认 `git status`，只 stage 该 bug 相关文件。
3. 执行提交：
   ```bash
   git add <该 bug 修改的文件>
   git commit -m "fix: <subject> #<issue_id>"
   ```
4. 更新清单「状态」字段为「已验证，已提交」，输出 commit hash。

**批量提交：** 逐条按顺序提交，每条独立 commit，不合并，不混入其他 bug 的改动。

---

## Step 7：DevFlow 状态机与强制复盘

所有 bug 验证并提交完成后：

### 更新 Meegle 状态
```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>
meegle comment add --work-item-id <id> \
  --content "🔧 修复完成\n\n根因：{摘要}\n修改文件：{file}\nDevFlow 工作项：{work-item-id}\n评分：{score}/100"
```

### 强制复盘
更新 `meta.json`：`status → reviewing`，`stages.coded = true`。

**自动触发复盘**，生成经验卡草稿，提示执行 `devflow retrospect` 确认入库。

---

## 产物规范

```
.bugfix-records/
└── <yyMMdd>/
    ├── batch-summary.md                   # 批量时必须（队列 ≥ 2 条）
    ├── <issue_id>-<bug简述>-bug修复清单.md
    └── <issue_id>-失败分析.md             # 失败时替代修复清单

.devflow/work-items/
└── {YYYYMMDD}-{bugSlug}/                  # DevFlow 工作项（含状态机）
```

## 失败处理

以下情况生成 `<issue_id>-失败分析.md` 并继续下一条：
- URL 不符合域名门禁（此时中止整批）
- Meegle 授权失败超过 3 次
- 缺失现象描述、预期描述或仓库/分支信息
- 分析评分 < 90，拒绝修复
- CodeGraph 爆炸半径 CRITICAL 且用户拒绝专项重构
- 编译验证失败且无法自动修复

失败文件必须说明已做的读取、判断和缺口内容。
