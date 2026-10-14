---
name: devflow-checklist
description: DevFlow 验收清单。生成真机验收步骤：进入路径、Mock 数据、逐条 AC 检查点、回归验证表。用户说「验收清单」「devflow checklist」时触发。
---

# devflow checklist

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/checklist.md
```

命令文件路径：`.devflow/commands/checklist.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
