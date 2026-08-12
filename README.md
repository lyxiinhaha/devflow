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
  <a href="#mcp-依赖"><img src="https://img.shields.io/badge/requires-CodeGraph%20MCP-f6ad55?style=flat-square" alt="requires CodeGraph"></a>
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
  <a href="#codegraph-的角色">CodeGraph</a> ·
  <a href="#mcp-依赖">MCP 依赖</a> ·
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
- **CodeGraph MCP** — 必须，代码知识图谱核心能力（见 [CodeGraph](https://github.com/nickseewald/codegraph)）
- **Meegle MCP** — 可选，接入项目管理全生命周期联动

### 安装

```bash
claude plugins install devflow
```

### 初始化项目（每个项目只需一次）

```
devflow init
```

AI 自动完成：检测技术栈并生成项目画像、配置 CodeGraph / Meegle、建立 `.devflow/` 目录、写入 `.gitignore`、确认安全分级、配置专项 Review Skill，以及可选的外部集成（YApi 域名、验收清单 Skill）。

支持两种场景：

- **已有项目** — 自动扫描特征文件识别技术栈
- **全新项目** — 对话式引导选择技术栈，可生成 `.gitignore` / `README.md` 骨架

初始化后，所有本地敏感配置（YApi 地址、Skill 名称等）写入 `.devflow/workspace.json`，该文件已加入 `.gitignore`，不会提交到仓库。

### 开始第一个需求

```bash
devflow start 用户头像上传 支持裁剪和预览

# 快速处理 Bug
devflow fix https://project.feishu.cn/...

# 新成员熟悉模块
devflow onboard payment 模块
```

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

### Bug 与重构

| 命令 | 功能说明 |
|------|---------|
| `devflow fix` | Meegle issue 批量处理，四阶段 CodeGraph 根因分析（含原子修复方案），90 分准入门禁，人工验证后提交 |
| `devflow refactor` | 测试基线验证，重构后一致性断言 |

### 知识与协作

| 命令 | 功能说明 |
|------|---------|
| `devflow onboard` | CodeGraph 架构导览，历史 Bug 热点，Meegle 近期工作项 |
| `devflow change` | Minor / Major 变更分级，状态机回退，受影响任务标记返工 |
| `devflow knowledge` | Bug 经验卡查询 / 添加 / 健康检查，历史防坑手册 |

<p align="right">(<a href="#20-个命令">返回顶部</a>)</p>

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

DevFlow 在以下节点强制调用 CodeGraph：

| 命令 | CodeGraph 调用 |
|------|--------------|
| `analyze` | 反查现有接口，避免重复实现 |
| `design` | 爆炸半径评估，HIGH / CRITICAL 触发强制确认 |
| `fix` | 四阶段根因分析，从入口到 DB 的完整调用链 |
| `review` | 变更影响范围验证 |
| `onboard` | 新成员架构全景导览 |

<p align="right">(<a href="#codegraph-的角色">返回顶部</a>)</p>

<a id="mcp-依赖"></a>

## MCP 依赖

| 依赖 | 必须/可选 | 配置方式 | 说明 |
|------|---------|---------|------|
| `codegraph` MCP | **必须** | `devflow init` 自动安装 | 代码知识图谱，爆炸半径分析，调用链追踪 |
| `meegle` MCP | 可选 | `devflow init` 引导配置 | 项目管理，工作项全生命周期联动 |
| `figma` MCP | 可选 | Figma Desktop 官方插件 | 需求分析阶段读取设计稿，降级使用 Framelink MCP |
| YApi | 可选 | `workspace.json` → `integrations.yapiHost` | WebFetch 直接读取接口定义（无需 MCP），降级使用 Apifox MCP |

<p align="right">(<a href="#mcp-依赖">返回顶部</a>)</p>

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
│   ├── config/                      # devflow.json、ai-policy.json、分级配置
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
