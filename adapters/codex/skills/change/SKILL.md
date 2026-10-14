---
name: devflow-change
description: DevFlow 需求变更。评估变更影响，回退受影响任务验证状态，写入回归义务。用户说「需求变更」「devflow change」时触发。
---

# devflow change

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/change.md
```

命令文件路径：`.devflow/commands/change.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
