---
inclusion: always
---

# DevFlow — AI 研发工作流

你正在使用 DevFlow，一套贴合 SDLC 全生命周期的 AI 研发工作流。

## 命令路由规则

当用户输入以 `devflow <command>` 开头，或语义上符合以下触发词时，**立即读取对应命令文件并严格按其指令执行**：

| 用户输入 | 读取文件 |
|---------|---------|
| `devflow init` / 初始化工作区 | `.devflow/commands/init.md` |
| `devflow start` / 开始新需求 | `.devflow/commands/start.md` |
| `devflow quick` / 快速需求 | `.devflow/commands/quick.md` |
| `devflow analyze` / 需求分析 | `.devflow/commands/analyze.md` |
| `devflow design` / 技术设计 | `.devflow/commands/design.md` |
| `devflow estimate` / 估算 | `.devflow/commands/estimate.md` |
| `devflow plan` / 任务拆解 | `.devflow/commands/plan.md` |
| `devflow code` / 开始编码 | `.devflow/commands/code.md` |
| `devflow checklist` / 验收清单 | `.devflow/commands/checklist.md` |
| `devflow review` / 代码审查 | `.devflow/commands/review.md` |
| `devflow retrospect` / 复盘 | `.devflow/commands/retrospect.md` |
| `devflow fix` / 修复 Bug | `.devflow/commands/fix.md` |
| `devflow refactor` / 重构 | `.devflow/commands/refactor.md` |
| `devflow onboard` / 了解模块 | `.devflow/commands/onboard.md` |
| `devflow continue` / 恢复进度 | `.devflow/commands/continue.md` |
| `devflow switch` / 切换工作项 | `.devflow/commands/switch.md` |
| `devflow list` / 查看工作项 | `.devflow/commands/list.md` |
| `devflow change` / 需求变更 | `.devflow/commands/change.md` |
| `devflow knowledge` / 知识库 | `.devflow/commands/knowledge.md` |
| `devflow sync` / 同步文件 | `.devflow/commands/sync.md` |
| `devflow doctor` / 环境诊断 | `.devflow/commands/doctor.md` |
| `devflow tour` / 新手向导 | `.devflow/commands/tour.md` |
| `devflow audit` / 审计日志 | `.devflow/commands/audit.md` |
| `devflow dashboard` / 进度看板 | `.devflow/commands/dashboard.md` |
| `devflow metrics` / 效能度量 | `.devflow/commands/metrics.md` |

在 Kiro CLI V3 中，上述命令同时以 `/devflow-<command>` 暴露，例如 `/devflow-start`。斜杠命令的参数视为对应命令文件中的 `$ARGUMENTS`。

## 工具使用规则

- **代码理解**：优先使用 CodeGraph MCP 或 `.devflow/tools/devflow-cg.sh`；不可用时降级为 Kiro CLI `code`、`grep_search`、`read_file`
- **WebFetch**：命令文件中的 WebFetch 在 Kiro CLI 中对应 `web_fetch`
- **Meegle / Figma / 飞书**：依赖项目配置的 MCP server 或对应 CLI；不可用时按可选集成跳过，不阻断核心流程
- **YApi / Apifox**：优先使用 `web_fetch`，需要认证时由用户提供凭证或配置对应 MCP
- **Hooks**：Kiro CLI V3 自动加载 `.kiro/hooks/devflow.json`，提供状态守卫和审计日志

## 工作区状态

所有工作项状态存储在 `.devflow/workspace.json`，命令执行前先读取当前状态。
