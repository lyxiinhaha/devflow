<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.9.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
</p>

<h1 align="center">DevFlow</h1>
<h3 align="center">AI-Powered SDLC Workflow · 完整贴合研发生命周期的 AI 工作流</h3>

<p align="center"><em style="font-family: 'PingFang SC', serif; font-size: 1.2em; color: #718096;">代码知图，研发有闭环</em></p>

<p align="center">
  <a href="./CHANGELOG.md"><img src="https://img.shields.io/badge/version-3.9.0-63b3ed?style=flat-square" alt="version"></a>
  <a href="#codegraph-的角色"><img src="https://img.shields.io/badge/requires-CodeGraph%20MCP-f6ad55?style=flat-square" alt="requires CodeGraph"></a>
  <a href="#工作流"><img src="https://img.shields.io/badge/SDLC-8%20阶段全覆盖-68d391?style=flat-square" alt="SDLC"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-68d391?style=flat-square" alt="license"></a>
</p>

<p align="center">
  <a href="#关于">关于</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#平台支持">平台支持</a> ·
  <a href="#工作流">工作流</a> ·
  <a href="#20-个命令">命令参考</a> ·
  <a href="#可选集成">可选集成</a> ·
  <a href="#codegraph-的角色">CodeGraph</a>
</p>

<br/>

<a id="关于"></a>

## 关于

大多数 AI 编码工具解决的是"如何写代码"，DevFlow 解决的是"如何完成一个需求"。20 个命令覆盖从需求分析到经验入库的完整 SDLC 闭环：

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
  <rect x="10" y="24" width="96" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="58" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">业务规划</text>
  <text x="58" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">start</text>
  <line x1="106" y1="46" x2="118" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="119" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="167" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">需求分析</text>
  <text x="167" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">analyze</text>
  <line x1="215" y1="46" x2="227" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="228" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="276" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">系统设计</text>
  <text x="276" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">design</text>
  <line x1="324" y1="46" x2="336" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="337" y="24" width="96" height="44" rx="8" fill="none" stroke="#718096" stroke-width="1.5"/>
  <text x="385" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">开发实践</text>
  <text x="385" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#718096">plan / code</text>
  <line x1="433" y1="46" x2="445" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="446" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="494" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">测试验证</text>
  <text x="494" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">review</text>
  <line x1="542" y1="46" x2="554" y2="46" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="555" y="24" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="603" y="42" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">上线交付</text>
  <text x="603" y="57" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">fix / release</text>
  <line x1="603" y1="68" x2="603" y2="118" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="555" y="119" width="96" height="44" rx="8" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="603" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">运维迭代</text>
  <text x="603" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#f6ad55">onboard</text>
  <line x1="555" y1="141" x2="543" y2="141" stroke="#718096" stroke-width="1.5" marker-end="url(#arrowGray)"/>
  <rect x="446" y="119" width="96" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="494" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">经验沉淀</text>
  <text x="494" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">retrospect</text>
  <line x1="446" y1="141" x2="434" y2="141" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>
  <rect x="337" y="119" width="96" height="44" rx="8" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="385" y="137" text-anchor="middle" font-size="11" font-family="sans-serif" fill="currentColor">知识库</text>
  <text x="385" y="152" text-anchor="middle" font-size="9" font-family="monospace" fill="#63b3ed">knowledge</text>
  <line x1="385" y1="119" x2="385" y2="68" stroke="#63b3ed" stroke-width="1.5" marker-end="url(#arrowBlue)"/>
  <text x="316" y="97" text-anchor="middle" font-size="9" font-family="sans-serif" fill="#63b3ed">plan 自动召回 ↑</text>
  <rect x="10" y="178" width="12" height="12" rx="2" fill="none" stroke="#f6ad55" stroke-width="1.5"/>
  <text x="26" y="189" font-size="9" font-family="sans-serif" fill="#718096">CodeGraph 调用节点</text>
  <rect x="175" y="178" width="12" height="12" rx="2" fill="none" stroke="#63b3ed" stroke-width="1.5"/>
  <text x="191" y="189" font-size="9" font-family="sans-serif" fill="#718096">经验闭环（retrospect → knowledge → plan）</text>
</svg>
</p>

| 特性 | 说明 |
|------|------|
| **SDLC 全闭环** | 8 个阶段，20 个命令，从需求收集到经验入库，没有断点 |
| **CodeGraph 深度融合** | 7 个关键节点强制调用图谱，爆炸半径评估、根因追踪、接口反查 |
| **Figma 三阶段集成** | analyze 读取节点建索引 → design 主动补全所有 UI 场景 → code 重读节点写代码，100% 还原设计稿 |
| **状态机驱动** | 每个工作项有明确状态，变更触发回退，防止遗漏 |
| **经验自动入库** | `retrospect` 将每次需求/Bug 提炼为经验卡，`plan` 自动召回，项目越用越聪明 |
| **安全分级门禁** | CRITICAL 变更强制确认，90 分准入门禁，review CRITICAL 阻断合并 |
| **多技术栈** | 自动识别 Android / iOS / KMP / Vue / React / Node.js / Spring Boot / Go / Python 等 |

> 完整版本历史见 [CHANGELOG.md](./CHANGELOG.md)。

---

<a id="快速开始"></a>

## 快速开始

```bash
# 1. 安装（Claude Code）
claude plugins install devflow

# 2. 初始化项目（每个项目一次）
devflow init

# 3. 创建第一个需求
devflow start 用户头像上传 支持裁剪和预览
```

> 其他平台见[平台支持](#平台支持)。遇到问题运行 `devflow doctor` 诊断环境。

---

<a id="平台支持"></a>

## 平台支持

| 平台 | 适配方式 | 状态 |
|------|---------|------|
| **Claude Code** | 官方插件（`claude plugins install devflow`） | ✅ 完整支持 |
| **Cursor** | `.cursor/rules/devflow.mdc` | ✅ 完整支持 · [使用手册](./README-Cursor.md) |
| **Kiro** | `.kiro/steering/devflow.md` | ✅ 完整支持 · [使用手册](./README-Kiro.md) |
| **Codex**（OpenAI） | `AGENTS.md` | ✅ 完整支持 |
| **OpenCode** | `OPENCODE.md` | ✅ 完整支持 |
| **Gemini CLI** | `GEMINI.md` | ✅ 完整支持 |

Cursor / Kiro / Codex / OpenCode / Gemini CLI 使用统一安装脚本：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh)
```

升级：`bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --update`

---

<a id="工作流"></a>

## 工作流

```
# 新功能
start → analyze → design → estimate → plan → code → review → retrospect

# 大型需求（Epic）
start epic → analyze → design
  └─ start feature --epic {id} ×N → plan（切片模式）→ code → review → retrospect

# Bug 修复
fix → retrospect（自动触发）

# 重构
refactor → review → retrospect
```

每条路径终点的 `retrospect` 将经验提炼入库，下次类似需求自动召回。

---

<a id="20-个命令"></a>

## 20 个命令

### 项目管理

| 命令 | 说明 |
|------|------|
| `devflow init` | 检测技术栈、配置 CodeGraph、生成 Review Skill，每个项目一次 |
| `devflow continue` | 新会话后恢复进度，自动展示未解决的开放问题 |
| `devflow list` | 工作项总览，展示 Epic 父子结构和共享模块冲突预警 |
| `devflow switch` | 多需求并行时切换焦点工作项 |
| `devflow sync` | 同步团队公共 skills / agents |

### 需求主线

| 命令 | 说明 |
|------|------|
| `devflow start` | 创建工作项，支持 `epic` 类型和 `--epic {id}` 子工作项 |
| `devflow analyze` | 贴入 PRD / 截图 / Figma / YApi 链接，AI 边接收边解析，歧义自动四分类；Figma 节点自动读取并建 node-id 索引 |
| `devflow quick` | `devflow quick 登录按钮改为「登录」` — 小需求一条命令，AI 自动判断路径 |
| `devflow design` | 爆炸半径评估 + 技术方案；主动索要缺失的 Figma 场景链接，在 design.md 顶部建完整节点索引表 |
| `devflow estimate` | 三点置信区间估算，可同步 Meegle 排期 |
| `devflow plan` | 拆解为原子任务，≥ 8 个任务自动提示切片模式 |

### 编码与交付

| 命令 | 说明 |
|------|------|
| `devflow code` | 按任务逐项编码；实现 UI 任务前强制重读 Figma 节点（DT token / RTL / 尺寸以最新读取为准），修改已有文件前强制阅读原逻辑，完成后编译验证 |
| `devflow checklist` | 生成验收清单：进入路径、Mock 数据、逐条 AC 检查点、回归验证表 |
| `devflow review` | 专项 Skill 或通用四维度审查，CRITICAL 阻断合并，APPROVED 后触发完成门禁 |
| `devflow retrospect` | 提炼经验卡入库，关闭工作项，完成 SDLC 闭环 |

### Bug 修复与重构

| 命令 | 说明 |
|------|------|
| `devflow fix` | 直接描述 / Meegle 链接 / ID，四阶段根因分析，人工验证门禁，强制复盘 |
| `devflow refactor` | 测试基线验证，重构后一致性断言 |

### 知识与协作

| 命令 | 说明 |
|------|------|
| `devflow onboard` | `devflow onboard payment 模块` — CodeGraph 架构导览 + 历史 Bug 热点 |
| `devflow change` | 需求变更，自动回退受影响任务验证状态，写入回归义务 |
| `devflow knowledge` | 查询 / 添加 / 蒸馏经验卡；`distill` 提炼为项目级规则，自动注入 plan / code / review |

---

<a id="可选集成"></a>

## 可选集成

只有 **CodeGraph MCP** 是必须的，其余全部可选，不配置时对应功能降级但不阻断流程。`devflow init` 时会逐一询问，直接回车跳过即可。

| 集成 | 配置后的增强 |
|------|------------|
| **Meegle（飞书项目）** | `devflow fix` 直接读取 issue，工作项状态自动同步飞书 |
| **YApi / Apifox** | `analyze` / `design` 自动反查接口定义，无需手动粘贴链接 |
| **Figma Desktop MCP** | `analyze` 读取节点并建索引 → `design` 补全所有 UI 场景节点索引表 → `code` 重读节点确保 100% 还原，颜色用 DT token，不 hardcode |
| **专项 Review Skill** | `review` 使用项目定制规范，比通用规范更精准 |

---

<a id="codegraph-的角色"></a>

## CodeGraph 的角色

没有 CodeGraph，AI 需要 40+ 次 grep / read_file 才能理解一条调用链，每次会话都从零重建认知——这叫**发现税**。

| 场景 | 无 CodeGraph | 有 CodeGraph |
|------|-------------|-------------|
| 定位符号及完整调用链 | 40+ 次工具调用，~40K tokens | 2-4 次图查询，~2K tokens |
| 爆炸半径评估 | 无法完成 | 原生支持，精确到符号 |
| 根因调用链追踪 | 逐文件手动推断 | 一次调用，毫秒级返回 |

DevFlow 在 `analyze` / `design` / `fix` / `review` / `onboard` 五个关键节点强制调用 CodeGraph，确保每次决策都有精确的符号级依据。

---

## 致谢

DevFlow 的核心能力建立在 **[CodeGraph](https://github.com/nickseewald/codegraph)** 之上——基于 tree-sitter 的确定性 AST 解析引擎，16+ 语言，SQLite 存储，Git Hooks 亚秒级增量更新。

<p align="center">问题反馈 · <a href="../../issues">GitHub Issues</a> · Made with intent by <strong>Yeesin</strong></p>
