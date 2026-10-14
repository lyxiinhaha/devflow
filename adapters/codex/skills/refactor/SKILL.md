---
name: devflow-refactor
description: DevFlow 代码重构。测试基线验证，重构后一致性断言。用户说「重构」「devflow refactor」时触发。
---

# devflow refactor

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/refactor.md
```

命令文件路径：`.devflow/commands/refactor.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
