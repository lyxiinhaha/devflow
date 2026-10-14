---
name: devflow-switch
description: DevFlow 切换工作项。多需求并行时切换焦点工作项。用户说「切换工作项」「devflow switch」时触发。
---

# devflow switch

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/switch.md
```

命令文件路径：`.devflow/commands/switch.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
