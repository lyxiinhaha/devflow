# DevFlow — AI 研发工作流

## 命令路由

当用户输入以 `devflow <command>` 开头，或语义符合触发词时，读取 `.devflow/commands/<command>.md` 并严格按其指令执行。

### 命令 → 文件映射

```
devflow init        → .devflow/commands/init.md
devflow start       → .devflow/commands/start.md
devflow quick       → .devflow/commands/quick.md
devflow analyze     → .devflow/commands/analyze.md
devflow design      → .devflow/commands/design.md
devflow estimate    → .devflow/commands/estimate.md
devflow plan        → .devflow/commands/plan.md
devflow code        → .devflow/commands/code.md
devflow checklist   → .devflow/commands/checklist.md
devflow review      → .devflow/commands/review.md
devflow retrospect  → .devflow/commands/retrospect.md
devflow fix         → .devflow/commands/fix.md
devflow refactor    → .devflow/commands/refactor.md
devflow onboard     → .devflow/commands/onboard.md
devflow continue    → .devflow/commands/continue.md
devflow switch      → .devflow/commands/switch.md
devflow list        → .devflow/commands/list.md
devflow change      → .devflow/commands/change.md
devflow knowledge   → .devflow/commands/knowledge.md
devflow sync        → .devflow/commands/sync.md
```

### 工具使用

- **CodeGraph MCP**：优先使用 `codegraph_explore` / `codegraph_impact` / `codegraph_trace`；未安装时降级为文件搜索
- **可选集成**（Meegle / Figma / YApi）：配置见 `.devflow/workspace.json`；未配置时跳过对应步骤

### 工作区状态

执行任意命令前先读取 `.devflow/workspace.json` 获取当前工作项状态。
