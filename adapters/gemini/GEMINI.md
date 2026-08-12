# DevFlow — AI 研发工作流

## 命令路由

当用户输入以 `devflow <command>` 开头，或语义符合触发词时，使用 `read_file` 读取对应命令文件并严格按其指令执行。

### 命令映射表

```
devflow init        → .devflow/commands/init.md        # 初始化工作区
devflow start       → .devflow/commands/start.md       # 创建新工作项
devflow quick       → .devflow/commands/quick.md       # 快速需求
devflow analyze     → .devflow/commands/analyze.md     # 需求分析
devflow design      → .devflow/commands/design.md      # 技术设计
devflow estimate    → .devflow/commands/estimate.md    # 工作量估算
devflow plan        → .devflow/commands/plan.md        # 任务拆解
devflow code        → .devflow/commands/code.md        # 执行编码
devflow checklist   → .devflow/commands/checklist.md   # 验收清单
devflow review      → .devflow/commands/review.md      # 代码审查
devflow retrospect  → .devflow/commands/retrospect.md  # 复盘入库
devflow fix         → .devflow/commands/fix.md         # Bug 修复
devflow refactor    → .devflow/commands/refactor.md    # 代码重构
devflow onboard     → .devflow/commands/onboard.md     # 模块导览
devflow continue    → .devflow/commands/continue.md    # 恢复进度
devflow switch      → .devflow/commands/switch.md      # 切换工作项
devflow list        → .devflow/commands/list.md        # 工作项列表
devflow change      → .devflow/commands/change.md      # 需求变更
devflow knowledge   → .devflow/commands/knowledge.md   # 知识库
devflow sync        → .devflow/commands/sync.md        # 同步文件
```

## 工具使用

- **CodeGraph MCP**：优先使用 `codegraph_explore` / `codegraph_impact` / `codegraph_trace`；未安装时降级为 `grep_search` / `read_file`
- **可选集成**（Meegle / Figma / YApi）：配置见 `.devflow/workspace.json`；未配置时跳过对应步骤

## 状态管理

每次命令执行前先 `read_file .devflow/workspace.json` 获取当前工作项和配置。
