# CodeGraph 多根目录查询规则
# 本文件由 devflow init 生成，供 analyze/design/code/fix 命令读取
# 所有 codegraph_explore / codegraph_impact 调用前必须先执行「根目录路由」

## 使用方式

每次需要调用 CodeGraph 前，先执行以下路由逻辑（伪代码）：

```
function cg_route(symbol_or_query):
  roots = read workspace.json → codegraph.roots
  if roots.length == 1:
    # 单根：直接在当前目录查
    codegraph_explore(symbol_or_query)
  else:
    # 多根：按 queryGuide 分发
    for root in roots:
      if symbol_belongs_to(root, symbol_or_query):
        cd root.path
        codegraph_explore(symbol_or_query)
        cd back
```

## 多根查询原则（来自 workspace.json.codegraph.queryGuide）

- **查符号定义 / 组件内部调用链**：去该组件对应的 root 路径执行
- **查全局影响（谁调用了该符号）**：在壳工程根目录（root[0]）执行
- **两次结果合并**得出完整影响面，缺一不可

## 索引新鲜度检查

在执行任何 codegraph 查询前，先检查索引是否可能过期：

```bash
codegraph status {root.path} | grep "up to date"
```

以下情况提示用户先重建：
- status 输出不含 "up to date"
- 距离上次 `pod install` / `pod update` 有未重建记录（workspace.json.codegraph.lastRebuild 早于 Podfile.lock 修改时间）
- submodule 有未同步的 commit

提示格式：
```
⚠️ CodeGraph 索引可能已过期（检测到 pod update / submodule 变更）
   建议先执行：codegraph index
   继续使用旧索引可能导致影响面分析不准确。是否继续？
```
