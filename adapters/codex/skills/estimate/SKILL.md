---
name: devflow-estimate
description: DevFlow 工作量估算。三点置信区间估算，可同步 Meegle 排期。用户说「估算」「devflow estimate」时触发。
---

# devflow estimate

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/estimate.md
```

命令文件路径：`.devflow/commands/estimate.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
