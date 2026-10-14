---
name: devflow-start
description: DevFlow 创建新工作项。开始一个新需求或 Epic，自动进入 Intake Mode 收录需求材料。用户说「开始新需求」「devflow start」时触发。
---

# devflow start

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/start.md
```

命令文件路径：`.devflow/commands/start.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
