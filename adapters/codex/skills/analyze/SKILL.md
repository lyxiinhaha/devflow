---
name: devflow-analyze
description: DevFlow 需求分析。流式收录 PRD/截图/Figma/YApi，边接收边解析，歧义四分类，生成 spec/requirement.md。用户说「需求分析」「devflow analyze」「就这些了」时触发。
---

# devflow analyze

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/analyze.md
```

命令文件路径：`.devflow/commands/analyze.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
