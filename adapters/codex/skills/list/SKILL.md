---
name: devflow-list
description: DevFlow 工作项列表。展示所有活跃工作项、Epic 父子结构、共享模块冲突预警。用户说「查看工作项」「devflow list」时触发。
---

# devflow list

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/list.md
```

命令文件路径：`.devflow/commands/list.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
