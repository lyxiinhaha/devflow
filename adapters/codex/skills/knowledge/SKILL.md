---
name: devflow-knowledge
description: DevFlow 知识库管理。查询/添加/去重/蒸馏/清理经验卡，输出知识库健康报告。用户说「知识库」「devflow knowledge」时触发。
---

# devflow knowledge

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/knowledge.md
```

命令文件路径：`.devflow/commands/knowledge.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
