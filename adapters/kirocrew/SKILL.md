---
name: devflow
description: DevFlow SDLC workflow — routes devflow commands to command files, injects project rules and experience cards into development tasks.
always: false
triggers: devflow, devflow start, devflow analyze, devflow design, devflow plan, devflow code, devflow review, devflow fix, devflow retrospect, devflow quick, devflow continue, devflow knowledge, devflow distill
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

## KiroCrew 专项说明

### Task Runner 集成

`devflow plan` 执行后会生成 `.devflow/work-items/<id>/tasks.md`。
可以直接用 KiroCrew Task Runner 执行编码阶段：

```
run .devflow/work-items/<work-item-id>/tasks.md
```

等效于 `devflow code`，且支持 KiroCrew 的断点续跑和进度面板。

### Knowledge Library 集成

DevFlow 知识库文件会自动被 KiroCrew 的知识图谱索引（需在 KiroCrew 中把
`.devflow/config/templates/knowledge/` 加入 Knowledge Library 文件夹）。

索引后可以直接用自然语言查询经验卡：
- "有没有关于 Dialog 崩溃的经验？"
- "金额计算有什么已知的坑？"

KiroCrew 的向量搜索会从经验卡中检索相关内容并引用原始文件位置。

### Memory / Lessons 集成

`devflow retrospect` 写入的 `project-rules.md` 内容可以手动同步到
KiroCrew 的 Lessons（工作区范围）：

```
记住：[project-rules.md 里的规则内容]
```

或直接在 KiroCrew 的 Lessons 页面添加，作用域选 Workspace。

## 工具使用规则

- **CodeGraph MCP**：已安装时优先通过 `codegraph_explore` / `codegraph_impact` 查询代码结构；未安装时降级为文件搜索
- **Meegle / Figma / YApi**：可选，配置见 `.devflow/workspace.json`；未配置时跳过

## 工作区状态

所有工作项状态存储在 `.devflow/workspace.json`，命令执行前先读取当前状态。
