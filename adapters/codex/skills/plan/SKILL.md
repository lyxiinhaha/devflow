---
name: devflow-plan
description: DevFlow 任务拆解。将技术设计拆解为原子任务，经验卡自动注入为编码约束，生成 tasks.md。用户说「任务拆解」「devflow plan」时触发。
---

# devflow plan

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/plan.md
```

命令文件路径：`.devflow/commands/plan.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
