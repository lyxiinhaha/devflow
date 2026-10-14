---
name: devflow-review
description: DevFlow 代码审查。专项 Skill 或通用四维度审查，CRITICAL 阻断合并，APPROVED 后触发完成门禁。用户说「代码审查」「devflow review」时触发。
---

# devflow review

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/review.md
```

命令文件路径：`.devflow/commands/review.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
