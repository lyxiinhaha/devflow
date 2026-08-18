<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.4.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
</p>

<h1 align="center">DevFlow</h1>
<h3 align="center">AI-Powered SDLC Workflow · 完整贴合研发生命周期的 AI 工作流</h3>

<p align="center"><em style="font-family: 'PingFang SC', serif; font-size: 1.2em; color: #718096;">代码知图，研发有闭环</em></p>

<p align="center">
  深度集成 CodeGraph 知识图谱 · 状态机驱动 · 经验自动入库<br/>
  从业务规划到运维迭代，20 个命令构建永不停止的研发闭环
</p>

<p align="center">
  <a href="./CHANGELOG.md"><img src="https://img.shields.io/badge/version-3.4.0-63b3ed?style=flat-square" alt="version"></a>
  <a href="#codegraph-的角色"><img src="https://img.shields.io/badge/requires-CodeGraph%20MCP-f6ad55?style=flat-square" alt="requires CodeGraph"></a>
  <a href="#完整工作流"><img src="https://img.shields.io/badge/SDLC-8%20阶段全覆盖-68d391?style=flat-square" alt="SDLC"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-68d391?style=flat-square" alt="license"></a>
  <a href="./CHANGELOG.md"><img src="https://img.shields.io/badge/changelog-Keep%20a%20Changelog-f6ad55?style=flat-square" alt="changelog"></a>
</p>

<br/>

<p align="center">
  <a href="#关于项目">关于</a> ·
  <a href="#whats-new">新特性</a> ·
  <a href="#支持的-ai-平台">平台支持</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#完整工作流">工作流</a> ·
  <a href="#20-个命令">命令参考</a> ·
  <a href="#可选集成">可选集成</a> ·
  <a href="#codegraph-的角色">CodeGraph</a> ·
  <a href="#致谢">致谢</a>
</p>

<br/>

<a id="关于项目"></a>

## 关于项目

大多数 AI 编码工具解决的是"如何写代码"，而 DevFlow 解决的是"如何完成一个需求"。

当 AI Agent 面对一个真实需求时，它需要的不只是代码生成能力，而是一套覆盖完整研发生命周期的决策框架：

<p align="center">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 740 210" width="740" height="210" role="img" aria-label="DevFlow SDLC 闭环流程图">
  <defs>
    <marker id="arrowGray" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#718096"/>
    </marker>
    <marker id="arrowBlue" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#63b3ed"/>
    </marker>
  </defs>

  <!-- ── Row 1：阶段 1–6，左→右 ── -->

  <!-- 1. 业务规划 -->
  <rect x="10" y="24" width="96" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="58" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">业务规划</text>
  <text x="58" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">start</text>
  <line x1="106" y1="46" x2="118" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 2. 需求分析 🟠 -->
  <rect x="119" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="167" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">需求分析</text>
  <text x="167" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">analyze</text>
  <line x1="215" y1="46" x2="227" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 3. 系统设计 🟠 -->
  <rect x="228" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="276" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">系统设计</text>
  <text x="276" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">design</text>
  <line x1="324" y1="46" x2="336" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 4. 开发实践 -->
  <rect x="337" y="24" width="96" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="385" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">开发实践</text>
  <text x="385" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">plan / code</text>
  <line x1="433" y1="46" x2="445" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 5. 测试验证 🟠 -->
  <rect x="446" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="494" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">测试验证</text>
  <text x="494" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">review</text>
  <line x1="542" y1="46" x2="554" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 6. 上线交付 🟠 -->
  <rect x="555" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="603" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">上线交付</text>
  <text x="603" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">fix / release</text>

  <!-- 上线交付 向下连到 Row 2 -->
  <line x1="603" y1="68" x2="603" y2="118" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- ── Row 2：阶段 7–8，右→左 ── -->

  <!-- 7. 运维迭代 🟠 -->
  <rect x="555" y="119" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="603" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">运维迭代</text>
  <text x="603" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">onboard</text>
  <line x1="555" y1="141" x2="543" y2="141" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>

  <!-- 8. 经验沉淀 🔵 -->
  <rect x="446" y="119" width="96" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="494" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">经验沉淀</text>
  <text x="494" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">retrospect</text>
  <line x1="446" y1="141" x2="434" y2="141" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>

  <!-- 知识库 🔵 -->
  <rect x="337" y="119" width="96" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="385" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">知识库</text>
  <text x="385" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">knowledge</text>

  <!-- 知识库 → plan 自动召回（蓝色闭环箭头，绕过 Row 1 开发实践） -->
  <line x1="385" y1="119" x2="385" y2="100" stroke="#63b3ed" stroke-width="1.5"/>
  <line x1="385" y1="100" x2="385" y2="68" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>
  <text x="316" y="97" text-anchor="middle" font-size="9" font-family="sans-serif" fill="#63b3ed">plan 自动召回 ↑</text>

  <!-- ── 图例 ── -->
  <rect x="10" y="178" width="12" height="12" rx="2" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="26" y="189" font-size="9" font-family="sans-serif" fill="#718096">CodeGraph 调用节点</text>
  <rect x="175" y="178" width="12" height="12" rx="2" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="191" y="189" font-size="9" font-family="sans-serif" fill="#718096">经验闭环（retrospect → knowledge → plan）</text>
</svg>
</p>

DevFlow 将这 8 个 SDLC 阶段映射为 20 个 AI 命令，并在每一个决策节点深度集成 **CodeGraph 知识图谱**，让 AI 能精确感知代码结构、调用关系和改动的爆炸半径——而不是靠猜测。

### 核心特性

| 特性 | 说明 |
|------|------|
| **SDLC 全闭环** | 8 个阶段，20 个命令，从需求收集到经验入库，没有断点 |
| **CodeGraph 深度融合** | 7 个关键节点强制调用图谱，爆炸半径评估、根因追踪、接口反查 |
| **状态机驱动** | 每个工作项有明确状态，变更触发回退，防止遗漏 |
| **经验自动入库** | `retrospect` 将每次需求/Bug 的经验提炼入库，后续自动召回 |
| **安全分级门禁** | CRITICAL 变更强制确认，90 分准入门禁，CRITICAL 阻断合并 |
| **跨项目技术栈** | 自动识别 Android / iOS / KMP / Vue / React / Node.js / Spring Boot / Go / Python 等 |
| **本地配置与仓库分离** | YApi 地址、专项 Skill 名等敏感配置写入 `.devflow/workspace.json`（已 gitignore），仓库保持干净 |
| **🆕 不确定项门禁分类** | 分析阶段对每个歧义做四分类（HardBlocker / ControlledPass / Assumption / OptItem），假设结构化记录，不再只活在对话里 |
| **🆕 开放问题持久化** | `open-issues.md` 跨会话托管未解决问题，新会话恢复时自动展示，「先放一放」的问题不再静默丢失 |
| **🆕 任务验证状态细分** | 任务完成状态从二值扩展为四级：`code_done → locally_verified → runtime_verified`，「审查通过」不再等同于「做完了」 |
| **🆕 完成门禁** | `review` APPROVED 后强制核查验证证据、未解除假设、跨模块回归义务，带已知风险合并需留记录 |
| **🆕 变更回归传播** | `change` 执行后自动标记受影响的已完成任务，降级验证状态并写入回归义务条目 |
| **🆕 Epic + 跨工作项依赖** | 大型需求可拆为 Epic（仅需求/设计，无编码）+ 多个子工作项，`list` 展示父子结构和共享模块冲突预警 |
| **🆕 改动前必读原逻辑** | `code` 阶段修改已有文件前强制阅读现有实现，`review` 退步检查自动识别原有保护被删除的情况 |

<p align="right">(<a href="#关于项目">返回顶部</a>)</p>

<a id="支持的-ai-平台"></a>

## 支持的 AI 平台

DevFlow 的核心是 20 个纯文本命令文件，任何能读取文件的 AI 工具都可以运行它。通过平台适配器（一个配置文件），AI 工具就能理解 `devflow <command>` 的路由规则。

| 平台 | 适配方式 | 状态 |
|------|---------|------|
| **Claude Code** | 官方插件（`claude plugins install`） | ✅ 完整支持 |
| **Cursor** | `.cursor/rules/devflow.mdc` | ✅ 完整支持 · [使用手册](./README-Cursor.md) |
| **Codex**（OpenAI） | `AGENTS.md` | ✅ 完整支持 |
| **OpenCode** | `OPENCODE.md` | ✅ 完整支持 |
| **Gemini CLI** | `GEMINI.md` | ✅ 完整支持 |
| 其他兼容工具 | 手动复制命令文件 + 自定义路由配置 | ✅ 通用支持 |

### Claude Code

```bash
claude plugins install devflow
```

### Cursor / Codex / OpenCode / Gemini CLI

在**项目目录**下运行一行命令，脚本自动下载安装并完成基础配置：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh)
```

脚本会交互式引导你完成：

1. **平台自动检测** — 识别 Cursor / Codex / Gemini CLI 等，直接确认即可
2. **文件安装** — 命令文件、适配配置、模板、`.gitignore` 全部就位
3. **基础配置** — 可选填写 YApi 域名、Meegle 项目 Key，直接回车跳过

安装完成后，在 AI 工具中打开项目，输入 `devflow init` 完成技术栈检测和 CodeGraph 配置。

> Cursor 用户请参阅 **[详细使用手册 →](./README-Cursor.md)**，包含从安装到日常开发的完整步骤说明。

**升级已安装的 DevFlow：**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --update
```

### 各平台适配文件说明

| 平台 | 适配文件 | 作用 |
|------|---------|------|
| Cursor | `.cursor/rules/devflow.mdc` | Cursor Rules，每次对话自动加载，AI 识别 `devflow` 命令路由 |
| Codex | `AGENTS.md`（追加） | OpenAI Codex Agent 配置，定义命令路由规则 |
| OpenCode | `OPENCODE.md`（追加） | OpenCode 配置文件，定义命令路由规则 |
| Gemini CLI | `GEMINI.md`（追加） | Gemini CLI 配置文件，定义命令路由规则 |

> 适配文件的内容很简单：一张"用户说 X → 读取文件 Y"的映射表。命令的实际逻辑全部在 `.devflow/commands/*.md` 里，各平台共用同一套，不重复维护。

<p align="right">(<a href="#支持的-ai-平台">返回顶部</a>)</p>

<a id="快速开始"></a>

## 快速开始

### 前置依赖

- **Claude Code** — DevFlow 基于 Claude Code 插件系统运行
- **CodeGraph MCP** — 必须安装，代码知识图谱核心能力（`devflow init` 会自动引导安装）

### 安装插件

```bash
claude plugins install devflow
```

---

### 已有项目

在已有项目的根目录执行初始化，**每个项目只需一次**：

```bash
cd /path/to/your-project
devflow init
```

init 会自动完成以下所有步骤，无需手动干预：

**1. 技术栈检测**

扫描特征文件（`build.gradle` / `Podfile` / `package.json` / `pom.xml` / `go.mod` 等），自动识别技术栈并生成项目画像，写入 `.devflow/devflow-profile.md`。支持的技术栈：

Android · iOS · KMP · Flutter · Vue · React / Next.js · Node.js · Spring Boot · Go · Python · Rust 等

**2. CodeGraph 索引**

根据项目结构自动选择索引策略：

| 项目类型 | 索引策略 |
|---------|---------|
| 单仓库 | 单根索引，一次 init 覆盖全部 |
| Android / KMP 含 submodules | 单根索引，壳工程根目录统一覆盖 |
| iOS CocoaPods 含本地 path Pod | 多根索引，壳工程 + 每个本地 Pod 分别建立索引 |
| 完全独立多仓库 | 多根索引，逐一 init |

**3. Review Skill 配置（可选）**

对每个检测到的技术栈，询问是否生成专项代码审查规范。选择「生成」则在 `.ai/skills/` 下创建可自定义的规范文件；选择「跳过」则 `devflow review` 使用内置通用规范。

**4. 外部集成配置（可选）**

询问 YApi / Figma / Meegle 等外部服务地址，写入本地 `.devflow/workspace.json`（不提交仓库）。全部可跳过，详见[可选集成](#可选集成)。

**5. 其他**

建立 `.devflow/` 目录结构、写入 `.gitignore`、确认安全分级。

初始化完成后，直接开始：

```bash
devflow start 用户头像上传 支持裁剪和预览
```

---

### 全新项目

空目录或只有 `.git/` 时，init 自动切换为对话式引导：

```bash
mkdir my-new-project && cd my-new-project
git init
devflow init
```

AI 会逐步询问：

```
这是一个全新项目，我来帮你完成初始配置。

请选择项目的主要技术栈：
  1. Android（Kotlin / Java）
  2. iOS（Swift / Objective-C）
  3. Vue 3
  4. React / Next.js
  5. Node.js 服务端
  6. Go
  ...（更多选项）

项目名称（直接回车跳过）：
是否生成 .gitignore？
是否生成 README.md 骨架？
```

收集完成后生成项目画像，并继续执行 Review Skill 配置和外部集成配置步骤（均可跳过）。

<p align="right">(<a href="#快速开始">返回顶部</a>)</p>

<a id="whats-new"></a>

## v3.4.0 新特性：需求控制层

这次更新的核心是一个问题：**AI 在执行大型需求时，信息只活在对话里**。新会话开始、假设被遗忘、「先放一放」的问题消失，于是重复踩坑、遗漏回归、测试发现时才知道做错了。

v3.4.0 把这些隐性状态显式化，落地为文件，让每个工作项的真实状态在任意会话都可以被还原。

---

### 不确定项门禁分类（analyze）

分析阶段，每个未解决的问题不再只是「待确认」，而是被分到四个桶里：

| 类型 | 含义 | 处理方式 |
|------|------|---------|
| **HardBlocker** | 核心目标/模块落地点不明确 | 🛑 停止，等确认后才能继续 |
| **ControlledPass** | 影响范围明确，有默认策略和恢复触发器 | 记录后可推进 |
| **Assumption** | 主动假设，记录四要素 | 结构化记录后允许推进 |
| **OptItem** | 不阻主线的优化项 | 跟踪但不阻塞 |

`requirement.md` 的歧义表格增加 `类型 / 当前假设/策略 / 影响范围 / 恢复触发器` 列，四要素留在文档里，不再只在对话里。

---

### 开放问题持久化（open-issues.md）

每个工作项新增 `open-issues.md`——一个跨会话的开放问题托管池。

- `analyze` Finalize 时，ControlledPass / Assumption 条目自动同步写入
- `code` 阶段遇到新问题时追加
- `change` 执行后自动追加回归义务条目
- `continue` 新会话恢复时**优先展示** open/paused 条目，不再丢失

```
⚠️ 开放问题（2 条 open/paused）：
   · OI-1：接口字段 X 语义假设（assumption，paused）
   · OI-2：切片 02 与切片 01 共享模块兼容性（integration，open）
```

---

### 任务验证状态四级（tasks.md）

任务的 `Verification` 字段取代简单的 ✅ 勾选：

```
not_started → code_done → locally_verified → runtime_verified
```

- `code_done`：代码改完，未本地运行验证
- `locally_verified`：本地运行通过，有截图/日志为证
- `runtime_verified`：真实环境/用户验收通过

`devflow review` APPROVED 只代表代码审查通过，不自动推进验证状态。

---

### 完成门禁（review）

`review` 通过后，进入合并步骤前触发四问核查（满足以下任一条件时触发：任务数 ≥ 5 / open-issues 有 open 条目 / CodeGraph 影响面 ≥ 2 个模块）：

```
Q1 验证状态    — 有几个任务还是 code_done，本地验证通过了吗？
Q2 未解除假设  — open-issues 还有几条 open/paused，不影响合并吗？
Q3 跨模块回归  — CodeGraph 影响了哪些模块，回归验证通过了吗？
Q4 回归义务   — 有几条 regression 条目还未核查？
```

可以回答「跳过 + 原因」，但原因必须记录进 `review.md`，不允许空过。

---

### 变更回归传播（change）

`devflow change` 现在多做一步：CodeGraph 评估完成后，扫描所有已完成任务的文件范围，命中影响面的任务自动：

- 降级 `Verification`（`locally_verified` → `code_done`）
- 追加注释 `<!-- ⚠️ 回归义务：受变更影响，需重新验证 -->`
- 在 `open-issues.md` 写入 `regression` 类型条目

区分「需返工（实现要改）」和「需回归验证（实现不变但要重验）」，不混淆。

---

### Epic + 跨工作项依赖（start / list）

大型需求不再只能靠一个超长 tasks.md 撑：

```bash
# 创建 Epic（只有需求和设计，无编码，工程映射节必填）
devflow start epic 期权详情页适配

# 创建子工作项，声明归属
devflow start feature 详情页切换 --epic 20260818-OptionDetailEpic
devflow start feature 盘前走势图 --epic 20260818-OptionDetailEpic
```

`devflow list` 展示父子结构和共享模块冲突预警：

```
[EPIC] 20260818-OptionDetailEpic   spec-only
    └─ 20260818-DetailPageSwitch   coding    ✓
    └─ 20260818-PremarketChart     designing  ⚠️ sharedWith: DetailPageSwitch → SharedDataLayer
```

---

### 改动前必读原逻辑（code / review）

`code` 阶段修改已有文件前，新增强制前置步骤：

> 原有逻辑做了 X，本次改动只增加/修改 Y，不影响 Z。

在动笔之前陈述这一句——这是防止「把原来功能搞丢」最有效的手段。

`review` 退步检查增加三条原逻辑保留性审查：原有 null/空值保护是否仍在、原有异常捕获是否仍在、返回值语义变化时调用方是否同步更新。前两条未满足直接 🔴 CRITICAL。

---

### 大型需求切片模式（plan）

`devflow plan` 检测到任务数 ≥ 8 时自动提示切片模式：

```
⚠️ 预估任务数 11 个，建议启用切片模式。
切片模式：按功能聚合为 2-5 个切片，每个切片有独立验证路径。
选择 [1=切片模式 / 2=标准模式，默认 2]：
```

切片模式下每个切片有独立的验证路径和切片状态，`devflow continue` 恢复时按切片展示进度。

<p align="right">(<a href="#关于项目">返回顶部</a>)</p>

<a id="完整工作流"></a>

## 完整工作流

### 主线：Feature / Tech 需求

```
start → analyze → design → estimate → plan → code → review → retrospect
```

### 大型需求（多模块 / 多切片）

```
start epic → analyze → design（工程映射）
  ↓
start feature --epic {id}  ×N  → analyze → design → plan（切片模式）→ code → review → retrospect
```

### Bug 修复

```
fix → [自动触发] retrospect
```

### 重构

```
refactor → review → retrospect
```

每条路径终点的 `retrospect` 将当次经验提炼入库，下一个类似需求时自动召回——这是 DevFlow 实现"自我进化"的核心机制。

<p align="right">(<a href="#完整工作流">返回顶部</a>)</p>

<a id="20-个命令"></a>

## 20 个命令

### 项目管理

| 命令 | 使用方式 |
|------|---------|
| `devflow init` | 每个项目执行一次，自动检测技术栈、配置 CodeGraph、生成 Review Skill |
| `devflow list` | 查看所有工作项；**Epic 父子结构可视化**，共享模块冲突预警 |
| `devflow switch` | 多需求并行时切换焦点工作项，自动恢复上下文 |
| `devflow continue` | 新会话 / 对话中断后恢复进度；**优先展示 open-issues.md 的未解决问题** |
| `devflow sync` | 同步团队公共 skills / agents 到当前项目 |

### 需求主线

| 命令 | 使用方式 |
|------|---------|
| `devflow start` | `devflow start 用户头像上传 支持裁剪和预览` — 创建工作项；**支持 `epic` 类型和 `--epic {id}` 子工作项声明** |
| `devflow analyze` | 输入命令后，把需求内容直接贴进来（PRD 文字 / 截图 / Figma 链接 / 接口链接，可分多次贴）；AI 边接收边解析；**歧义问题自动四分类，假设结构化记录** |
| `devflow quick` | `devflow quick 登录按钮文案改为「登录」` — 小需求一条命令，AI 自动判断是否需要走完整流程 |
| `devflow design` | 接续 analyze，AI 做爆炸半径评估，生成含时序图 / 接口签名 / 验收清单的技术方案；**多模块时提示填写工程映射和共享边界** |
| `devflow estimate` | 三点置信区间估算，历史 Bug 密度因子，可更新 Meegle 排期 |
| `devflow plan` | 将设计文档拆解为标准化原子任务；**任务数 ≥ 8 时自动提示切片模式，每切片独立验证路径** |

### 编码与交付

| 命令 | 使用方式 |
|------|---------|
| `devflow code` | 按 tasks.md 逐项编码，lint / test 质量门禁，所有任务完成后自动编译验证；**修改已有文件前强制阅读原逻辑**；`noworktree` 参数可跳过独立分支 |
| `devflow checklist` | 生成可直接交付测试的验收清单：进入路径、Mock 数据构造、逐条 AC 检查点、回归验证表 |
| `devflow review` | 代码审查，优先使用项目专项 Review Skill，CRITICAL 问题阻断合并；**APPROVED 后触发四问完成门禁**；审查通过后可直接合并或提 MR/PR |
| `devflow retrospect` | 提炼经验卡入库，关闭 Meegle 工作项，完成整个需求闭环 |

### Bug 修复

`devflow fix` 支持三种输入方式：

```bash
# 方式一：直接描述 bug 现象（无需任何外部工具）
devflow fix 点击提交按钮后页面白屏，控制台报 TypeError: Cannot read properties of null

# 方式二：Meegle issue 链接（需配置 Meegle，见可选集成）
devflow fix https://project.feishu.cn/...

# 方式三：Meegle 工作项 ID
devflow fix 12345678
```

AI 执行四阶段 CodeGraph 根因分析（定位入口 → 追踪调用链 → 评估爆炸半径 → 生成原子修复方案），90 分准入门禁，人工验证后提交，强制触发 `retrospect` 将修复经验入库。

| 命令 | 功能说明 |
|------|---------|
| `devflow fix` | 支持直接描述 / Meegle issue / 批量视图，四阶段根因分析，最小修复原则 |
| `devflow refactor` | 测试基线验证，重构后一致性断言 |

### 知识与协作

| 命令 | 使用方式 |
|------|---------|
| `devflow onboard` | `devflow onboard payment 模块` — 新成员快速了解指定模块，CodeGraph 导览 + 历史 Bug 热点 |
| `devflow change` | 需求中途变更时使用，Minor / Major 分级，状态机自动回退到正确阶段；**自动扫描已完成任务，命中影响面的任务降级验证状态，写入回归义务条目** |
| `devflow knowledge` | 查询 / 添加 Bug 经验卡，历史防坑手册，`devflow plan` 会自动召回相关经验 |

<p align="right">(<a href="#20-个命令">返回顶部</a>)</p>

<a id="可选集成"></a>

## 可选集成

DevFlow 只有 **CodeGraph MCP** 是必须的，其余外部服务全部可选。没有这些服务照样可以完整使用，只是对应功能会降级处理。

执行 `devflow init` 时会逐一询问，直接回车跳过即可；也可以事后手动编辑 `.devflow/workspace.json` 补充配置。

---

### Meegle（飞书项目）

**不配置的影响：** `devflow fix` 只能通过直接描述 bug 触发，无法读取 issue 详情；工作项状态不会同步到飞书项目；`devflow continue` 不展示 Meegle 状态。其余所有命令正常运行。

**配置方式：** `devflow init` 时执行 `meegle auth login` 完成授权，或事后运行：

```bash
meegle auth login
```

授权成功后 init 会自动写入 `workspace.json.meegle.projectKey`。

---

### Figma

**不配置的影响：** `devflow analyze` 收到 Figma 链接时无法自动读取设计稿，会标注「待手动核验」继续流程，不阻断分析。

**配置方式：** 安装 [Figma Desktop MCP](https://help.figma.com/hc/en-us/articles/24028694536215)（官方插件），Claude Code 自动识别。降级方案：安装 Framelink MCP。

---

### YApi / Apifox（接口文档）

**不配置的影响：** `devflow analyze` 和 `devflow design` 跳过 YApi 自动反查步骤，不影响核心分析流程；如需读取接口，直接粘贴完整 YApi 链接即可（AI 从 URL 提取 host，无需提前配置）。

**配置方式：** `devflow init` 时填写 YApi 域名，或手动编辑：

```json
// .devflow/workspace.json
{
  "integrations": {
    "yapiHost": "yapi.your-company.com"
  }
}
```

配置后 analyze / design 会在 CodeGraph 反查后自动补充接口定义，无需手动粘贴链接。

降级方案：YApi 不可用时自动切换 Apifox MCP（名称「API 文档」）。

---

### 专项 Review Skill / 验收清单 Skill

**不配置的影响：** `devflow review` 使用内置通用四维度审查规范；`devflow checklist` 使用内置通用验收清单格式。对大多数项目已足够。

**配置方式：** `devflow init` 时选择「生成默认规范文件」，AI 会在 `.ai/skills/` 下生成可自定义的规范文件，并自动写入 `workspace.json`。也可以指定已有 skill 路径：

```json
// .devflow/workspace.json
{
  "reviewSkills": [
    {
      "name": "my-review-android",
      "triggerWhen": "diff 含 *.kt 且存在 AndroidManifest.xml",
      "path": ".ai/skills/my-review-android"
    }
  ],
  "checklistSkill": "my-acceptance-checklist"
}
```

<p align="right">(<a href="#可选集成">返回顶部</a>)</p>

<a id="codegraph-的角色"></a>

## CodeGraph 的角色

> CodeGraph 是给 AI 代理的一张**可查询的建筑蓝图**，而不是让它每次都从头摸索整栋大楼。

### 发现税问题

在没有 CodeGraph 的情况下，AI 需要 40+ 次 grep / read\_file 调用才能理解一条完整调用链。每次会话都从零重建对代码库的认知——这笔开销被称为**发现税（Discovery Tax）**。

| 场景 | 无 CodeGraph | 有 CodeGraph |
|------|-------------|-------------|
| 定位符号及完整调用链 | 40+ 次工具调用，~40K tokens | 2-4 次图查询，~2K tokens |
| 爆炸半径评估 | 无法完成 | 原生支持，精确到符号 |
| 根因调用链追踪 | 逐文件手动推断 | 一次调用，毫秒级返回 |
| 死代码识别 | 不支持 | 可达性分析原生支持 |
| 结果确定性 | 可能遗漏 | 100% 确定，零幻觉 |

### DevFlow 中的关键节点

| 命令 | CodeGraph 调用 |
|------|--------------|
| `analyze` | 反查现有接口，避免重复实现 |
| `design` | 爆炸半径评估，HIGH / CRITICAL 触发强制确认 |
| `fix` | 四阶段根因分析，从入口到 DB 的完整调用链 |
| `review` | 变更影响范围验证 |
| `onboard` | 新成员架构全景导览 |

<p align="right">(<a href="#codegraph-的角色">返回顶部</a>)</p>

## 目录结构

```
plugins/devflow/
├── .claude-plugin/plugin.json       # 插件元数据
├── commands/                        # 20 个命令（含 frontmatter，支持自动触发）
│   ├── init.md                      # 技术栈检测 + 项目画像 + Review Skill 配置
│   ├── analyze.md                   # 需求分析 + 歧义四分类 + 假设记录
│   ├── plan.md                      # 任务拆解 + 切片模式（≥8 任务自动触发）
│   ├── code.md                      # 编码执行 + 改动前必读原逻辑 + 编译验证
│   ├── review.md                    # 专项 Skill 委托 + 四问完成门禁 + 原逻辑保留审查
│   ├── change.md                    # 变更处理 + 回归义务传播
│   ├── start.md                     # 工作项创建 + Epic 类型 + 子工作项声明
│   ├── list.md                      # 工作项列表 + Epic 父子展示 + 共享模块冲突预警
│   ├── continue.md                  # 进度恢复 + open-issues.md 优先展示
│   ├── checklist.md                 # 真机验收清单（含 Worktree 路径）
│   ├── quick.md                     # 快速需求（三路径自动判断）
│   ├── sync.md                      # 团队 AI 文件同步
│   └── ...（其余 8 个命令）
├── assets/templates/
│   ├── requirement.tpl.md           # 需求模板（含歧义四分类表格）
│   ├── tasks.tpl.md                 # 任务模板（含 Deviation + Verification 字段）
│   ├── design.tpl.md                # 设计模板（含工程映射节）
│   ├── open-issues.tpl.md           # 开放问题托管模板 🆕
│   ├── meta.tpl.json                # 工作项元数据（含验证状态字段 + Epic 支持）
│   └── ...
├── references/
│   ├── pressure-scenarios.md        # 压力场景参考文档（8 个边界场景）🆕
│   ├── codegraph-routing.md         # CodeGraph 多根目录查询规则
│   └── meegle-integration.md        # Meegle CLI 调用速查
├── skills/
│   ├── devflow-cg/
│   │   └── devflow-cg.sh            # CodeGraph 多根路由脚本
│   └── devflow-sync/
│       └── sync-ai-files.sh         # 团队 AI 文件同步脚本
├── ai-files/
│   ├── skills/                      # 团队公共 skills（由团队维护，devflow sync 分发）
│   └── agents/                      # 团队公共 agents（可选）
└── assets/config/                   # workspace.tpl.json、ai-policy.json、分级配置
```

<p align="right">(<a href="#关于项目">返回顶部</a>)</p>

<a id="致谢"></a>

## 致谢

DevFlow 的核心能力建立在 **[CodeGraph](https://github.com/nickseewald/codegraph)** 之上。

CodeGraph 是一个基于确定性 AST 解析的代码知识图谱引擎。它以 tree-sitter 解析 16+ 语言，以 SQLite 邻接表存储符号与调用关系，通过 Git Hooks 实现亚秒级增量更新，把 AI 代理每次重新摸索代码库的高昂发现税压缩到毫秒级的图查询。

没有 CodeGraph 提供的精确符号定位、调用链追踪和爆炸半径分析，DevFlow 的 SDLC 闭环将无法实现。

<p align="right">(<a href="#致谢">返回顶部</a>)</p>

## 联系方式

- **问题反馈**：[GitHub Issues](../../issues)

<br/>

<p align="center">Made with intent by <strong>Yeesin</strong></p>

