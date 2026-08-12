# DevFlow — AI 研发工作流

## 命令路由规则

当用户输入以 `devflow <command>` 开头，或语义符合触发词时，**立即读取对应命令文件并严格按其指令执行**。

| 命令 | 文件路径 | 触发词 |
|------|---------|-------|
| `devflow init` | `.devflow/commands/init.md` | 初始化工作区、devflow init |
| `devflow start` | `.devflow/commands/start.md` | 开始新需求、新建工作项 |
| `devflow quick` | `.devflow/commands/quick.md` | 快速需求 |
| `devflow analyze` | `.devflow/commands/analyze.md` | 需求分析 |
| `devflow design` | `.devflow/commands/design.md` | 技术设计 |
| `devflow estimate` | `.devflow/commands/estimate.md` | 工作量估算 |
| `devflow plan` | `.devflow/commands/plan.md` | 任务拆解 |
| `devflow code` | `.devflow/commands/code.md` | 开始编码 |
| `devflow checklist` | `.devflow/commands/checklist.md` | 验收清单 |
| `devflow review` | `.devflow/commands/review.md` | 代码审查 |
| `devflow retrospect` | `.devflow/commands/retrospect.md` | 复盘总结 |
| `devflow fix` | `.devflow/commands/fix.md` | 修复 Bug |
| `devflow refactor` | `.devflow/commands/refactor.md` | 代码重构 |
| `devflow onboard` | `.devflow/commands/onboard.md` | 了解模块 |
| `devflow continue` | `.devflow/commands/continue.md` | 恢复进度 |
| `devflow switch` | `.devflow/commands/switch.md` | 切换工作项 |
| `devflow list` | `.devflow/commands/list.md` | 查看工作项 |
| `devflow change` | `.devflow/commands/change.md` | 需求变更 |
| `devflow knowledge` | `.devflow/commands/knowledge.md` | 知识库 |
| `devflow sync` | `.devflow/commands/sync.md` | 同步文件 |

## 工具使用

- **CodeGraph MCP**：优先使用 `codegraph_explore` / `codegraph_impact` / `codegraph_trace`；未安装时降级为文件搜索
- **可选集成**（Meegle / Figma / YApi）：配置见 `.devflow/workspace.json`；未配置时跳过对应步骤，不阻断流程

## 状态管理

执行任意命令前读取 `.devflow/workspace.json` 获取当前工作项和配置状态。
