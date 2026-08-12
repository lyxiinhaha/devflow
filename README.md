<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.3.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
</p>

<h1 align="center">DevFlow</h1>
<h3 align="center">AI-Powered SDLC Workflow · 完整贴合研发生命周期的 AI 工作流</h3>

<p align="center"><em style="font-family: 'PingFang SC', serif; font-size: 1.2em; color: #718096;">代码知图，研发有闭环</em></p>

<p align="center">
  深度集成 CodeGraph 知识图谱 · 状态机驱动 · 经验自动入库<br/>
  从业务规划到运维迭代，20 个命令构建永不停止的研发闭环
</p>

<p align="center">
  <a href="./CHANGELOG.md"><img src="https://img.shields.io/badge/version-3.3.0-63b3ed?style=flat-square" alt="version"></a>
  <a href="#codegraph-的角色"><img src="https://img.shields.io/badge/requires-CodeGraph%20MCP-f6ad55?style=flat-square" alt="requires CodeGraph"></a>
  <a href="#完整工作流"><img src="https://img.shields.io/badge/SDLC-8%20阶段全覆盖-68d391?style=flat-square" alt="SDLC"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-68d391?style=flat-square" alt="license"></a>
  <a href="./CHANGELOG.md"><img src="https://img.shields.io/badge/changelog-Keep%20a%20Changelog-f6ad55?style=flat-square" alt="changelog"></a>
</p>

<br/>

<p align="center">
  <a href="#关于项目">关于</a> ·
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

```
业务规划 → 需求分析 → 系统设计 → 开发实践 → 测试验证 → 上线交付 → 运维迭代
   ↑                                                                      |
   └──────────────────────── 新需求触发，闭环永不停止 ──────────────────────┘
```

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

<p align="right">(<a href="#关于项目">返回顶部</a>)</p>

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

<a id="完整工作流"></a>

## 完整工作流

### 主线：Feature / Tech 需求

```
start → analyze → design → estimate → plan → code → review → retrospect
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

| 命令 | 功能说明 |
|------|---------|
| `devflow init` | 自动检测技术栈，生成项目画像，配置专项 Review Skill，建立工作区 |
| `devflow list` | 状态总览，Active / Paused / Completed 分组显示 |
| `devflow switch` | 切换工作项，自动恢复上下文 |
| `devflow continue` | 读取 Checkpoint，新会话快速恢复，展示 Meegle 状态 |
| `devflow sync` | 同步团队公共 skills / agents 到当前项目，维护软链接和 .gitignore |

### 需求主线

| 命令 | 功能说明 |
|------|---------|
| `devflow start` | 创建工作项，进入需求收集模式（Intake Mode） |
| `devflow quick` | 快速需求：需求描述直接输入，跳过 PRD，一步完成分析 |
| `devflow analyze` | 边录边析，逐段即时解析，读 Figma / YApi，CodeGraph 反查现有接口 |
| `devflow design` | 爆炸半径评估，边设计边追问，冻结后生成含时序图 / 接口签名 / 埋点 / 验收清单的对外技术方案 |
| `devflow estimate` | 三点置信区间估算，历史 Bug 密度因子，可更新 Meegle 排期 |
| `devflow plan` | 标准化任务格式，Bug 经验召回，静默输出 tasks.md |

### 编码与交付

| 命令 | 功能说明 |
|------|---------|
| `devflow code` | 执行范围选择，编码禁令，lint / test 质量门禁，**所有任务完成后自动编译验证** |
| `devflow checklist` | 生成真机验收清单：进入路径、Mock 数据、逐条 AC 检查点、回归验证表，含 Worktree 绝对路径 |
| `devflow review` | 优先使用项目专项 Review Skill，未配置时降级通用四维度审查，CRITICAL 阻断合并 |
| `devflow retrospect` | 经验卡去重入库，关闭 Meegle 工作项 |

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

| 命令 | 功能说明 |
|------|---------|
| `devflow onboard` | CodeGraph 架构导览，历史 Bug 热点，Meegle 近期工作项 |
| `devflow change` | Minor / Major 变更分级，状态机回退，受影响任务标记返工 |
| `devflow knowledge` | Bug 经验卡查询 / 添加 / 健康检查，历史防坑手册 |

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
│   ├── code.md                      # 编码执行 + 编译验证
│   ├── review.md                    # 专项 Skill 委托 + 通用四维度审查
│   ├── checklist.md                 # 真机验收清单（含 Worktree 路径）
│   ├── quick.md                     # 快速需求（三路径自动判断）
│   ├── sync.md                      # 团队 AI 文件同步
│   └── ...（其余 14 个命令）
├── skills/
│   ├── devflow-cg/
│   │   └── devflow-cg.sh            # CodeGraph 多根路由脚本
│   └── devflow-sync/
│       └── sync-ai-files.sh         # 团队 AI 文件同步脚本
├── ai-files/
│   ├── skills/                      # 团队公共 skills（由团队维护，devflow sync 分发）
│   └── agents/                      # 团队公共 agents（可选）
├── assets/
│   ├── config/                      # workspace.tpl.json、ai-policy.json、分级配置
│   └── templates/                   # 文档模板 + bug-experience-cards.csv（20 条内置经验）
└── references/
    ├── codegraph-routing.md         # CodeGraph 多根目录查询规则
    └── meegle-integration.md        # Meegle CLI 调用速查
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

