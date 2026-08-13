# DevFlow 优势放大 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 通过四项改动放大 DevFlow 的核心优势：经验召回可见化、CodeGraph 效率账单、SDLC 流程 SVG、README-Cursor 同步更新。

**Architecture:** 纯文本命令文件改动（.md）+ workspace 模板 JSON 字段新增 + README 内嵌 SVG。不涉及任何可执行代码，所有改动对 AI 运行时立即生效。

**Tech Stack:** Markdown 命令文件、JSON、SVG（内嵌到 Markdown）

---

## 文件改动清单

| 文件 | 改动性质 | 说明 |
|------|---------|------|
| `plugins/devflow/commands/plan.md` | 改造 | 经验召回输出可见化 + tasks.md 标注来源卡号 |
| `plugins/devflow/commands/fix.md` | 改造 | Step 2 结束后写入 stats + 输出效率账单 |
| `plugins/devflow/commands/design.md` | 改造 | Step 3 结束后写入 stats + 输出效率账单 |
| `plugins/devflow/assets/config/workspace.tpl.json` | 改造 | 新增 `stats` 字段 |
| `README.md` | 改造 | ASCII 流程图替换为内嵌 SVG |
| `README-Cursor.md` | 改造 | CodeGraph 关键节点表更新 + 指向主 README 流程图 |

---

## Task 1：plan.md — 经验召回可见化

**Files:**
- Modify: `plugins/devflow/commands/plan.md`

### 改动说明

**改动一：Step 2 召回逻辑增加"注入位置记录"要求**

在「### 2. Bug 经验召回」步骤中，要求 AI 在匹配经验卡时记录每张卡注入到了哪些任务 ID，以便输出时展示。

**改动二：tasks.md 的「Bug 经验编码禁令」章节标注卡号来源**

在任务格式规范中，要求每条来自经验卡的约束标注卡号前缀。

**改动三：输出块展开经验卡列表**

将 `召回 Bug 经验卡：{n} 条` 展开为逐行格式。

- [ ] **Step 1：修改 Step 2 召回逻辑，增加注入位置记录要求**

找到 `plan.md` 中「### 2. Bug 经验召回」节，将现有内容：

```markdown
读取 `bug-experience-cards.csv`，匹配与当前需求涉及模块、接口、字段相关的经验卡：
- 命中经验卡的「禁止反模式」→ 转化为**实现约束**，写入对应任务描述
- 命中经验卡的「要求测试」→ 转化为**验收标准**，写入对应任务验收项
- 未命中或知识库不可读 → 注明「未召回 Bug 经验」，正常继续
```

替换为：

```markdown
读取 `bug-experience-cards.csv`，匹配与当前需求涉及模块、接口、字段相关的经验卡：
- 命中经验卡的「禁止反模式」→ 转化为**实现约束**，写入对应任务描述
- 命中经验卡的「要求测试」→ 转化为**验收标准**，写入对应任务验收项
- 未命中或知识库不可读 → 注明「未召回 Bug 经验」，正常继续

**注入位置记录（供输出展示用）：** 每张命中的经验卡，记录其被注入的任务 ID 列表（如 T003、T007），格式：`{ cardId, severity, title, injectedTasks: [T001, ...] }`。用于步骤 5 输出时展示。
```

- [ ] **Step 2：修改任务格式规范，要求经验卡约束标注卡号**

找到任务格式规范中的验收标准行：

```markdown
    - [ ] {来自 Bug 经验卡的验收项（如有）}
```

替换为：

```markdown
    - [ ] {来自 Bug 经验卡的验收项，格式：`[KB-{id}]` 约束描述（如有）}
```

找到「Bug 经验编码禁令」章节说明（在「### 4. 强约束验证」中）：

```markdown
- Bug 经验编码禁令（来自经验卡的约束，无命中时写「无」）
```

在其下方紧接着补充格式示例：

```markdown
- Bug 经验编码禁令（来自经验卡的约束，无命中时写「无」）

  格式示例：
  ```markdown
  ## Bug 经验编码禁令
  - [KB-015] 禁止使用 Float/Double 处理金额，必须用 BigDecimal
  - [KB-009] Token 刷新必须加锁，防止并发多次刷新
  ```
```

- [ ] **Step 3：修改输出块，展开经验卡列表**

找到「## 输出」节中的输出模板，将：

```
  召回 Bug 经验卡：{n} 条
```

替换为：

```
  召回 Bug 经验卡：{n} 条
    · KB-{id}  [{severity}]  {title} → 注入 {T001, T002, ...}
    · KB-{id}  [{severity}]  {title} → 注入 {T003}
    （未命中时此列表不显示）
```

- [ ] **Step 4：验证改动完整性**

检查 `plan.md` 确认以下三处均已修改：
1. Step 2 末尾有「注入位置记录」说明
2. 任务格式规范中验收标准有 `[KB-{id}]` 格式要求
3. 输出块中召回行已展开为列表格式

- [ ] **Step 5：提交**

```bash
git add plugins/devflow/commands/plan.md
git commit -m "feat(plan): 经验召回输出可见化，展示卡号/severity/注入任务"
```

---

## Task 2：workspace.tpl.json — 新增 stats 字段

**Files:**
- Modify: `plugins/devflow/assets/config/workspace.tpl.json`

### 改动说明

新增 `stats` 顶级字段，用于累计 CodeGraph 调用次数统计。fix 和 design 命令执行后会读写此字段。

- [ ] **Step 1：在 workspace.tpl.json 末尾新增 stats 字段**

读取当前文件内容（已知结构见上文），在最后一个 `}` 前插入：

```json
  "stats": {
    "totalCgQueries": 0,
    "totalCgQueriesSaved": 0,
    "lastUpdated": null
  }
```

完整文件结构应为：

```json
{
  "focus": null,
  "activeWorkItems": [],
  "meegle": {
    "projectKey": null,
    "defaultWorkItemType": null
  },
  "integrations": {
    "yapiHost": "",
    "yapiProjectId": null
  },
  "checklistSkill": null,
  "reviewSkills": [],
  "codegraph": {
    "strategy": "single-root",
    "roots": [
      { "path": ".", "covers": "整个项目" }
    ],
    "moduleRootMap": {},
    "lastRebuildAt": null
  },
  "stats": {
    "totalCgQueries": 0,
    "totalCgQueriesSaved": 0,
    "lastUpdated": null
  }
}
```

字段说明：
- `totalCgQueries`：累计 CodeGraph 查询次数（每次 explore/impact 各计 1）
- `totalCgQueriesSaved`：累计节省的等效 grep/read 调用次数（每次 CG 查询 ≈ 节省 10 次）
- `lastUpdated`：最后更新日期（YYYY-MM-DD）

- [ ] **Step 2：提交**

```bash
git add plugins/devflow/assets/config/workspace.tpl.json
git commit -m "feat(workspace): 新增 stats 字段用于 CodeGraph 调用次数统计"
```

---

## Task 3：fix.md — CodeGraph 效率账单

**Files:**
- Modify: `plugins/devflow/commands/fix.md`

### 改动说明

在 Step 2「根因分析（四阶段 CodeGraph 法）」结束后，AI 统计本次实际执行的 CG 查询次数，写入 `workspace.json` stats 字段，并在最终输出的汇总块中追加效率摘要。

**统计规则（写入命令提示词）：**
- 每执行一次 `devflow-cg explore` 或 `devflow-cg impact` 计 1 次
- 等效 grep/read 节省量：每次 CG 查询 ≈ 节省 10 次工具调用
- 写入方式：读取 `workspace.json`，`totalCgQueries += 本次次数`，`totalCgQueriesSaved += 本次次数 × 10`，`lastUpdated = 今日日期`

- [ ] **Step 1：在 Step 2 末尾（CodeGraph 不可用降级说明之后）新增统计指令**

找到 fix.md 中 Step 2 的最后一行：

```markdown
CodeGraph 不可用时：降级 grep/find + Read 手动搜索，分析文件中注明"CodeGraph 不可用，使用手动搜索"。
```

在其后插入（保持同一节内）：

```markdown

### CodeGraph 调用统计

Step 2 全部执行完成后，统计本次实际执行的 CG 查询次数（每次 `devflow-cg explore` 或 `devflow-cg impact` 调用各计 1）：

1. 读取 `.devflow/workspace.json` 的 `stats` 字段（若字段不存在则初始化为 `{ totalCgQueries: 0, totalCgQueriesSaved: 0, lastUpdated: null }`）
2. `totalCgQueries += 本次查询次数`
3. `totalCgQueriesSaved += 本次查询次数 × 10`（每次 CG 查询等效节省约 10 次 grep/read）
4. `lastUpdated = 今日日期（YYYY-MM-DD）`
5. 将更新后的 `stats` 写回 `.devflow/workspace.json`
6. 将本次查询次数存入变量 `cgQueriesThisRun`，供 Step 5 输出使用

CodeGraph 不可用（降级为 grep/read）时：`cgQueriesThisRun = 0`，不更新 stats。
```

- [ ] **Step 2：在 Step 5 输出汇总块末尾追加效率摘要**

找到 Step 5 输出模板：

```markdown
确认每条验证通过后，请告知「第 N 条验证通过」或「全部验证通过」，
我将分别使用以下 commit message 逐条提交：
```

在整个输出块（含上方的修复摘要和验证建议）的最末尾，追加：

```markdown

── CodeGraph 效率摘要 ──────────────────────────
  本次图查询：{cgQueriesThisRun} 次（节省 ≈ {cgQueriesThisRun × 10} 次 grep/read）
  累计节省调用：{totalCgQueriesSaved} 次
  （CodeGraph 不可用时此摘要不显示）
```

- [ ] **Step 3：验证改动**

检查 fix.md 确认：
1. Step 2 末尾有「CodeGraph 调用统计」小节，含读写 workspace.json 的完整步骤
2. Step 5 输出块末尾有「CodeGraph 效率摘要」块
3. 两处均引用同一变量 `cgQueriesThisRun`，保持一致

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/commands/fix.md
git commit -m "feat(fix): 新增 CodeGraph 效率账单，统计真实调用次数并累计入 stats"
```

---

## Task 4：design.md — CodeGraph 效率账单

**Files:**
- Modify: `plugins/devflow/commands/design.md`

### 改动说明

与 fix.md 相同逻辑，在 Step 3「CodeGraph 深度分析」结束后统计并写入 stats，在最终输出块追加效率摘要。

- [ ] **Step 1：在 Step 3 末尾新增统计指令**

找到 design.md 中「### 3. CodeGraph 深度分析」节的最后一个子节「#### 3.3 安全策略检查」末尾：

```markdown
- 在文档中标注 `🔒 [L0 — 需人工审批]`
```

在其后插入新小节：

```markdown

#### 3.4 CodeGraph 调用统计

Step 3 全部执行完成后，统计本次实际执行的 CG 查询次数（每次 `devflow-cg explore` 或 `devflow-cg impact` 调用各计 1）：

1. 读取 `.devflow/workspace.json` 的 `stats` 字段（若字段不存在则初始化为 `{ totalCgQueries: 0, totalCgQueriesSaved: 0, lastUpdated: null }`）
2. `totalCgQueries += 本次查询次数`
3. `totalCgQueriesSaved += 本次查询次数 × 10`
4. `lastUpdated = 今日日期（YYYY-MM-DD）`
5. 将更新后的 `stats` 写回 `.devflow/workspace.json`
6. 将本次查询次数存入变量 `cgQueriesThisRun`，供最终输出使用

CodeGraph 不可用（降级）时：`cgQueriesThisRun = 0`，不更新 stats。
```

- [ ] **Step 2：在最终输出块末尾追加效率摘要**

找到 design.md 「## 输出」节的输出模板末尾（`Meegle 同步：{已同步 | 未配置}` 之后），追加：

```markdown
  ── CodeGraph 效率摘要 ────────────────────────
  本次图查询：{cgQueriesThisRun} 次（节省 ≈ {cgQueriesThisRun × 10} 次 grep/read）
  累计节省调用：{totalCgQueriesSaved} 次
  （CodeGraph 不可用时此摘要不显示）
```

- [ ] **Step 3：验证改动**

检查 design.md 确认：
1. Step 3 末尾有「3.4 CodeGraph 调用统计」小节
2. 输出块末尾有效率摘要
3. 变量名 `cgQueriesThisRun` 和 `totalCgQueriesSaved` 拼写与 fix.md 一致

- [ ] **Step 4：提交**

```bash
git add plugins/devflow/commands/design.md
git commit -m "feat(design): 新增 CodeGraph 效率账单，统计真实调用次数并累计入 stats"
```

---

## Task 5：README.md — ASCII 流程图替换为内嵌 SVG

**Files:**
- Modify: `README.md`

### 改动说明

将「关于项目」节中的 ASCII 流程图替换为内嵌 SVG。SVG 设计要求：
- 宽 700px，自适应高度
- 8 个阶段横向排列（或两排）
- CodeGraph 调用节点（analyze/design/fix/review/onboard）用橙色 `#f6ad55` 标出
- `retrospect → knowledge → plan` 闭环用蓝色 `#63b3ed` 箭头单独标注
- 支持 GitHub 暗色/亮色模式（文字用 `currentColor`，背景透明）

**8 个阶段与对应命令：**
1. 业务规划 — `start`
2. 需求分析 — `analyze` 🟠
3. 系统设计 — `design` 🟠
4. 开发实践 — `plan` / `code`
5. 测试验证 — `checklist` / `review` 🟠
6. 上线交付 — `fix` 🟠
7. 运维迭代 — `refactor` / `onboard` 🟠
8. 经验沉淀 — `retrospect` → `knowledge` 🔵闭环

- [ ] **Step 1：在 README.md 中找到 ASCII 流程图，替换为 SVG**

找到以下内容：

```markdown
```
业务规划 → 需求分析 → 系统设计 → 开发实践 → 测试验证 → 上线交付 → 运维迭代
   ↑                                                                      |
   └──────────────────────── 新需求触发，闭环永不停止 ──────────────────────┘
```
```

替换为以下 SVG（完整内嵌）：

```markdown
<p align="center">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 740 200" width="740" height="200" role="img" aria-label="DevFlow SDLC 闭环流程图">
  <defs>
    <marker id="arrowGray" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#718096"/>
    </marker>
    <marker id="arrowBlue" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#63b3ed"/>
    </marker>
    <marker id="arrowOrange" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#f6ad55"/>
    </marker>
  </defs>

  <!-- Row 1: 阶段 1-5 -->
  <!-- 业务规划 -->
  <rect x="10" y="20" width="88" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="54" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">业务规划</text>
  <text x="54" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">start</text>

  <!-- arrow -->
  <line x1="98" y1="42" x2="112" y2="42" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 需求分析 🟠 -->
  <rect x="113" y="20" width="88" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="157" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">需求分析</text>
  <text x="157" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">analyze</text>

  <!-- arrow -->
  <line x1="201" y1="42" x2="215" y2="42" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 系统设计 🟠 -->
  <rect x="216" y="20" width="88" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="260" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">系统设计</text>
  <text x="260" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">design</text>

  <!-- arrow -->
  <line x1="304" y1="42" x2="318" y2="42" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 开发实践 -->
  <rect x="319" y="20" width="88" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="363" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">开发实践</text>
  <text x="363" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">plan / code</text>

  <!-- arrow -->
  <line x1="407" y1="42" x2="421" y2="42" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 测试验证 🟠 -->
  <rect x="422" y="20" width="88" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="466" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">测试验证</text>
  <text x="466" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">review</text>

  <!-- 测试验证 向右向下箭头 到 上线交付 -->
  <line x1="510" y1="42" x2="524" y2="42" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 上线交付 🟠 -->
  <rect x="525" y="20" width="88" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="569" y="38" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">上线交付</text>
  <text x="569" y="54" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">fix / release</text>

  <!-- 上线交付 向下 -->
  <line x1="569" y1="64" x2="569" y2="114" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- Row 2: 阶段 6-8 从右到左 -->

  <!-- 运维迭代 🟠 -->
  <rect x="525" y="115" width="88" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="569" y="133" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">运维迭代</text>
  <text x="569" y="149" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">onboard</text>

  <!-- arrow 向左 -->
  <line x1="525" y1="137" x2="511" y2="137" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 经验沉淀 🔵 -->
  <rect x="422" y="115" width="88" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="466" y="133" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">经验沉淀</text>
  <text x="466" y="149" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">retrospect</text>

  <!-- 经验沉淀 向左 -->
  <line x1="422" y1="137" x2="408" y2="137" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>

  <!-- 知识库 🔵 -->
  <rect x="319" y="115" width="88" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="363" y="133" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">知识库</text>
  <text x="363" y="149" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">knowledge</text>

  <!-- 知识库 向左上 回到 开发实践（plan 召回） -->
  <line x1="319" y1="130" x2="283" y2="130" stroke="#63b3ed" stroke-width="1.5"/>
  <line x1="283" y1="130" x2="283" y2="64" stroke="#63b3ed" stroke-width="1.5"/>
  <line x1="283" y1="64" x2="319" y2="64" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>

  <!-- 闭环标注 -->
  <text x="230" y="128" text-anchor="middle" font-size="9" font-family="sans-serif" fill="#63b3ed">plan 自动召回</text>

  <!-- 图例 -->
  <rect x="10" y="170" width="12" height="12" rx="2" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="26" y="181" font-size="9" font-family="sans-serif" fill="#718096">CodeGraph 调用节点</text>
  <rect x="160" y="170" width="12" height="12" rx="2" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="176" y="181" font-size="9" font-family="sans-serif" fill="#718096">经验闭环（retrospect → knowledge → plan）</text>
</svg>
</p>
```

- [ ] **Step 2：验证 SVG 在 README 中位置正确**

确认：
1. SVG 紧接在「当 AI Agent 面对一个真实需求时...」段落之后
2. SVG 之后紧接「DevFlow 将这 8 个 SDLC 阶段映射为...」那行文字
3. 没有多余的空代码块残留

- [ ] **Step 3：提交**

```bash
git add README.md
git commit -m "docs(readme): ASCII 流程图替换为内嵌 SVG，标注 CodeGraph 节点与经验闭环"
```

---

## Task 6：README-Cursor.md — 同步更新

**Files:**
- Modify: `README-Cursor.md`

### 改动说明

两处更新：
1. 在「痛点 1」的 CodeGraph 解法描述里，补充一句"累计节省调用次数"的说明（呼应新的 stats 功能）
2. 在 Cursor README 里没有重复放 SVG，但在合适位置加一行指向主 README 流程图的链接

- [ ] **Step 1：在「痛点 2」解法中补充 CodeGraph 效率账单说明**

找到 README-Cursor.md 中：

```markdown
DevFlow 的解法：
- `devflow design` 强制做**爆炸半径评估**，HIGH / CRITICAL 级别改动触发确认门禁，改之前就知道影响哪些符号
- `devflow review` 用 CodeGraph 验证影响面，发现超出预期的改动直接阻断
```

替换为：

```markdown
DevFlow 的解法：
- `devflow design` 强制做**爆炸半径评估**，HIGH / CRITICAL 级别改动触发确认门禁，改之前就知道影响哪些符号
- `devflow review` 用 CodeGraph 验证影响面，发现超出预期的改动直接阻断
- `devflow fix` / `devflow design` 每次执行后输出 **CodeGraph 效率摘要**，显示本次节省的 grep/read 调用次数，累计数字写入本地 `workspace.json`
```

- [ ] **Step 2：在末尾汇总表之后补充流程图引用**

找到 README-Cursor.md 中的痛点汇总表（`| Cursor 痛点 | DevFlow 对应能力 |` 那张表），在表格结束后紧接着添加：

```markdown

> 完整的 SDLC 闭环流程图（含 CodeGraph 调用节点标注）请见 [主 README → 关于项目](./README.md#关于项目)。
```

- [ ] **Step 3：验证改动**

检查 README-Cursor.md 确认：
1. 「痛点 2」解法新增了效率摘要说明
2. 痛点汇总表后有流程图引用链接
3. 没有引入任何链接格式错误

- [ ] **Step 4：提交**

```bash
git add README-Cursor.md
git commit -m "docs(readme-cursor): 补充效率账单说明，添加 SDLC 流程图引用"
```

---

## 自检清单

| 需求 | 对应任务 | 覆盖？ |
|------|---------|--------|
| plan 显示经验召回卡号/severity/注入位置 | Task 1 | ✅ |
| tasks.md 经验约束标注卡号来源 | Task 1 Step 2 | ✅ |
| workspace.tpl.json 新增 stats 字段 | Task 2 | ✅ |
| fix 统计 CG 查询次数并写入 stats | Task 3 Step 1 | ✅ |
| fix 输出效率摘要（调用次数 + 累计节省） | Task 3 Step 2 | ✅ |
| design 统计 CG 查询次数并写入 stats | Task 4 Step 1 | ✅ |
| design 输出效率摘要 | Task 4 Step 2 | ✅ |
| README.md ASCII 流程图 → SVG | Task 5 | ✅ |
| SVG 标注橙色 CodeGraph 节点 | Task 5 SVG | ✅ |
| SVG 标注蓝色经验闭环箭头 | Task 5 SVG | ✅ |
| README-Cursor.md 补充效率账单说明 | Task 6 Step 1 | ✅ |
| README-Cursor.md 添加流程图引用 | Task 6 Step 2 | ✅ |
| 两份 README 均已更新 | Task 5 + Task 6 | ✅ |
