# DevFlow × Kiro CLI 安装与使用手册

本文面向 Kiro CLI V3。DevFlow 同时保留 Kiro IDE Steering 支持，但斜杠命令、项目 Agent、CLI Hooks 和无头运行均以 Kiro CLI V3 为基准。

## 1. 能力与兼容性

| 能力 | Kiro CLI 支持情况 | DevFlow 适配方式 |
|---|---|---|
| 25 个工作流命令 | 完整支持 | `.kiro/prompts/devflow-*.md`，输入 `/` 自动补全 |
| 命令参数 | 完整支持 | 通过 `$ARGUMENTS` 原样传入命令文件 |
| 自然语言路由 | 完整支持 | 项目 Agent `devflow` 加载 Steering 路由表 |
| 文件读写、Shell、Git、Web | 完整支持 | 使用 Kiro CLI V3 原生工具 |
| 代码理解 | 完整支持并可降级 | CodeGraph MCP/CLI → Kiro `code` → grep/read |
| 状态守卫与审计 | 完整支持 | `.kiro/hooks/devflow.json` 的 `PreToolUse` / `PostToolUse` |
| Worktree | 完整支持 | `.devflow/tools/worktree-setup.sh` |
| 风险扫描与知识库 | 完整支持 | 规范和模板随项目安装，不依赖外部 Skill 目录 |
| 会话恢复 | 完整支持 | `/devflow-continue`；也可用 `kiro-cli --resume` |
| Figma | 条件支持 | 需配置 Figma MCP；不可用时记录链接并降级 |
| Meegle / 飞书 | 条件支持 | 需安装对应 CLI 或 MCP server；不影响核心流程 |
| YApi / Apifox | 条件支持 | 公网接口使用 `web_fetch`；鉴权接口需凭证或 MCP |
| 后台进程控制 | 有限制 | CLI 可启动后台命令，但没有 IDE 的进程控制工具；DevFlow 默认使用前台构建/测试 |
| Kiro Powers | CLI 不支持 | DevFlow 核心流程不依赖 Powers |

## 2. 前置条件

安装并登录 Kiro CLI：

```bash
brew install kirocli
kiro-cli login
kiro-cli --version
```

DevFlow 推荐使用 Kiro CLI V3。若需要 CodeGraph 增强代码关系分析，再安装：

```bash
npm install -g @colbymchenry/codegraph
codegraph --version
```

`jq` 用于 DevFlow Hook 的状态校验与审计。未安装时 Hook 会安全放行，但不会生成完整审计记录：

```bash
brew install jq
```

## 3. 安装 DevFlow

在目标项目根目录执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) \
  --platform kiro \
  --dir "$PWD"
```

无人值守安装可跳过可选集成问答：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) \
  --platform kiro \
  --dir "$PWD" \
  --skip-config
```

安装后会生成：

```text
.kiro/
├── agents/devflow.json          # Kiro CLI 项目 Agent
├── hooks/devflow.json           # 状态守卫 + 审计 Hook
├── prompts/devflow-*.md         # 25 个斜杠命令
├── settings/mcp.json            # 无损合并 CodeGraph MCP
└── steering/devflow.md          # 命令路由与平台规则
.devflow/
├── commands/                    # 25 个完整工作流定义
├── hooks/                       # Hook 执行脚本
├── tools/                       # CodeGraph、Worktree、风险扫描等运行时工具
└── config/                      # 工作区模板与知识库
```

安装器不会覆盖 `mcp.json` 中已有的 MCP server，也不会覆盖已有的 `project-rules.md`。

## 4. 启动与验证

在项目根目录启动专用 Agent：

```bash
kiro-cli chat --v3 --agent devflow
```

进入会话后：

```text
/prompts list
/devflow-doctor
/devflow-init
```

也可以在终端验证 Agent 配置：

```bash
kiro-cli agent validate --path .kiro/agents/devflow.json
kiro-cli agent list
```

Agent 不固定模型，会沿用用户的 Kiro 默认模型。若启动提示默认模型不可用，先运行 `kiro-cli chat --list-models`，再在会话中通过 `/model` 选择，或启动时传入 `--model <可用模型ID>`。

如果 `/` 中没有 DevFlow 命令，请确认当前目录是项目根目录、会话使用 V3，并重新启动会话。旧引擎仍可使用 `@devflow-init` 形式，但建议直接切换 V3。

## 5. 命令速查

### 初始化与导航

| 命令 | 用途 |
|---|---|
| `/devflow-init` | 初始化项目画像、CodeGraph 和可选集成 |
| `/devflow-doctor [--quick\|--fix]` | 检查 Agent、Prompt、Hook、工具与集成 |
| `/devflow-tour` | 交互式新手向导 |
| `/devflow-list` | 查看全部工作项 |
| `/devflow-switch <工作项>` | 切换当前工作项 |
| `/devflow-continue` | 恢复进度和风险上下文 |

### 功能研发

| 命令 | 用途 |
|---|---|
| `/devflow-start <类型> <描述> [noworktree]` | 创建工作项，默认建立 Worktree |
| `/devflow-quick <描述>` | 自动选择极简、快速或完整路径 |
| `/devflow-analyze` | 需求收集与规格分析 |
| `/devflow-design` | 技术设计和影响面分析 |
| `/devflow-estimate` | 工作量估算 |
| `/devflow-plan` | 原子任务拆解 |
| `/devflow-code [noworktree]` | 按任务实施并验证 |
| `/devflow-checklist` | 生成验收清单 |
| `/devflow-review` | 代码、影响面和精简度审查 |
| `/devflow-retrospect` | 复盘并沉淀经验 |

### 专项与治理

| 命令 | 用途 |
|---|---|
| `/devflow-fix <问题或 issue URL>` | Bug 根因分析与修复 |
| `/devflow-refactor <目标>` | 有基线保护的重构 |
| `/devflow-change <变更>` | 需求变更与回归义务传播 |
| `/devflow-onboard <模块>` | 生成代码库导览 |
| `/devflow-knowledge <子命令>` | 查询、维护和蒸馏知识库 |
| `/devflow-audit [参数]` | 查询 Hook 审计与决策轨迹 |
| `/devflow-dashboard [--push\|--sheet]` | 全局进度与风险看板 |
| `/devflow-metrics [--push]` | 效能度量报告 |
| `/devflow-sync` | 同步团队 AI 文件 |

## 6. 常用工作流

完整功能开发：

```text
/devflow-start feature 用户头像上传
/devflow-analyze
/devflow-design
/devflow-plan
/devflow-code
/devflow-review
/devflow-retrospect
```

小改动：

```text
/devflow-quick 详情页右上角增加分享按钮
```

Bug 修复：

```text
/devflow-fix 点击提交按钮后白屏，控制台出现 TypeError
```

## 7. 可选集成

### CodeGraph

安装器会向 `.kiro/settings/mcp.json` 无损加入：

```json
{
  "mcpServers": {
    "codegraph": {
      "type": "stdio",
      "command": "codegraph",
      "args": ["serve", "--mcp"]
    }
  }
}
```

若本地 CodeGraph 版本使用其他启动参数，请按该版本文档修改。启动时要求 MCP 必须成功，可使用：

```bash
kiro-cli chat --v3 --agent devflow --require-mcp-startup
```

### Figma、Meegle 与飞书

这些能力不是 Kiro CLI 内置工具。请把对应 MCP server 加入 `.kiro/settings/mcp.json`，或安装命令文件所需的 CLI。未配置时，DevFlow 会保留链接或待办并继续核心研发流程；`dashboard --push`、`dashboard --sheet`、`metrics --push` 等外部写操作会跳过。

## 8. 无头与 CI 模式

无头模式不能使用交互式斜杠命令，应直接给 DevFlow Agent 自然语言指令：

```bash
export KIRO_API_KEY='由密钥管理系统注入'
kiro-cli chat --v3 \
  --agent devflow \
  --model '<当前账号可用的模型ID>' \
  --no-interactive \
  --trust-tools=read_file,grep_search \
  "执行 devflow audit --blocked，仅输出审计结果，不修改文件"
```

涉及写入、Shell 或 MCP 时，优先通过 Kiro permissions 配置精确授权。只有在受控环境中才使用 `--trust-all-tools`。

## 9. 更新与卸载提示

更新：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) \
  --update \
  --dir "$PWD"
```

更新会刷新命令、运行时工具、Agent、Prompt 和 Hook，并保留 `workspace.json`、工作项、已有 MCP server 与项目规则。

DevFlow 当前没有自动卸载命令。若需移除，请先备份 `.devflow/work-items/`，再人工删除 DevFlow 创建的 `.kiro/agents/devflow.json`、`.kiro/hooks/devflow.json`、`.kiro/prompts/devflow-*.md` 和 `.devflow/`；不要整体删除 `.kiro/`，其中可能包含项目已有配置。
