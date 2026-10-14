---
name: devflow-init
description: DevFlow 项目初始化。检测技术栈、配置 CodeGraph、生成 Review Skill。项目首次接入 DevFlow 时使用。用户说「初始化项目」「devflow init」时触发。
---

# devflow init

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/init.md
```

命令文件路径：`.devflow/commands/init.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
