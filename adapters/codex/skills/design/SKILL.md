---
name: devflow-design
description: DevFlow 技术设计。CodeGraph 爆炸半径评估，Figma 节点索引建立，生成技术方案和接口签名。用户说「技术设计」「devflow design」时触发。
---

# devflow design

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/design.md
```

命令文件路径：`.devflow/commands/design.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
