---
name: devflow-code
description: DevFlow 执行编码。按 tasks.md 逐项实现，UI 任务前重读 Figma 节点，改动前必读原逻辑，完成后编译验证。用户说「开始编码」「devflow code」时触发。
---

# devflow code

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/code.md
```

命令文件路径：`.devflow/commands/code.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
