---
name: devflow-sync
description: DevFlow 同步团队 AI 文件。将团队公共 skills/agents 同步到当前项目。用户说「同步 skill」「devflow sync」时触发。
---

# devflow sync

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/sync.md
```

命令文件路径：`.devflow/commands/sync.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
