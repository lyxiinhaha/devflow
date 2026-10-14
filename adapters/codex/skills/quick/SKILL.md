---
name: devflow-quick
description: DevFlow 快速需求。适合小改动（文案/样式/单接口），AI 自动判断路径：≤2文件直接编码，影响大自动转完整流程。用户说「快速需求」「devflow quick」时触发。
---

# devflow quick

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/quick.md
```

命令文件路径：`.devflow/commands/quick.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
