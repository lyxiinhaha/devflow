---
name: devflow-onboard
description: DevFlow 模块导览。CodeGraph 架构导览 + 历史 Bug 热点，快速理解陌生模块。用户说「了解模块」「devflow onboard」时触发。
---

# devflow onboard

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/onboard.md
```

命令文件路径：`.devflow/commands/onboard.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
