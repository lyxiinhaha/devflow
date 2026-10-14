---
name: devflow-retrospect
description: DevFlow 复盘入库。提炼经验卡入库，关闭工作项，完成 SDLC 闭环。用户说「复盘」「devflow retrospect」时触发。
---

# devflow retrospect

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/retrospect.md
```

命令文件路径：`.devflow/commands/retrospect.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
