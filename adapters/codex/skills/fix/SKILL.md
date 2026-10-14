---
name: devflow-fix
description: DevFlow Bug 修复。四阶段 CodeGraph 根因分析：入口定位→调用链追踪→爆炸半径→原子修复，人工验证门禁，强制 retrospect。用户说「修复 bug」「devflow fix」时触发。
---

# devflow fix

读取命令文件并严格按其指令执行：

```
read_file .devflow/commands/fix.md
```

命令文件路径：`.devflow/commands/fix.md`

执行前先读取 `.devflow/workspace.json` 获取当前工作项状态。

> $ARGUMENTS 作为参数传入命令文件中的 $ARGUMENTS 占位符。
