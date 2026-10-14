---
name: devflow-continue
description: DevFlow 恢复进度。新会话后读取 Checkpoint，恢复上次工作项状态，优先展示未解决的开放问题。用户说「恢复进度」「devflow continue」时触发。
---

# devflow continue

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/continue.md
```

命令文件路径：`.devflow/commands/continue.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
