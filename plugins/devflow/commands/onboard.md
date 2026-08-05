---
name: devflow-onboard
description: DevFlow 代码库入职导览。利用 CodeGraph 为新成员生成模块架构报告，关联 Meegle 近期工作项。当用户说「了解某某模块」「代码库入职」「devflow onboard」或新成员需要快速上手某个模块时触发。
---

# devflow onboard — 代码库入职导览

**用途：** 利用 CodeGraph 为新成员或不熟悉特定模块的开发者生成结构化架构导览报告，包含调用关系、历史 Bug 热点和 Meegle 近期工作项，将 1-2 周入职理解时间压缩至 30 分钟。

---

## 前置条件

- 项目已初始化（`.devflow/` 存在）。
- 需提供目标模块名称或业务领域（通过 `$ARGUMENTS`）。

---

## 执行步骤

### 1. 确定目标模块

解析用户输入的模块名称或业务领域。

**模块不存在处理：** 若 CodeGraph 和本地搜索均未找到对应模块，输出：
```
✗ 未找到模块「{input}」。
  可用模块建议（基于目录结构）：
  - {src/module1}
  - {src/module2}
  请重新指定目标模块。
```

### 2. 核心入口点（CodeGraph）

```
codegraph_explore("<模块名> entry point interface public API")
```

找出该模块暴露给外部的主要接口、公开函数或入口类。

### 3. 调用关系拓扑（CodeGraph）

```
codegraph_explore("<核心入口符号> 调用链 数据流")
```

生成模块内部的数据流向：入参 → 业务逻辑 → 出参。

### 4. 高频依赖

找出该模块最常调用的底层组件（依赖注入、工具函数、数据层等）。

### 5. 历史 Bug 热点

读取 `bug-experience-cards.csv`，筛选 `module` 字段匹配当前模块的经验卡，列出历史高频 Bug 和必须遵守的防坑指南。

### 6. 可选：Meegle 近期工作项

若 `workspace.json` 配置了 `meegle.projectKey`：
```bash
meegle workitem query \
  --project-key <key> \
  --mql "SELECT name, status, priority FROM story WHERE name LIKE '%<模块名>%' LIMIT 10"
```

---

## 输出格式

生成《{模块} 架构导览报告》：

```markdown
# {模块名} 架构导览报告

## 1. 模块职责（一句话）
{职责描述}

## 2. 核心组件
| 文件路径 | 函数/类 | 说明 |
|---------|--------|------|
| `src/auth/login.js` | `handleLogin()` | 登录入口 |

## 3. 数据流向
Client → `login.js` → `user.js` → `jwt.js` → Client

## 4. 关键依赖
- 依赖 `src/db/user.js` 进行数据访问
- 依赖 `src/cache/redis.js` 缓存 Token

## 5. 历史 Bug 热点
| 经验卡 | 问题描述 | 防坑建议 |
|--------|---------|---------|
| KB-009 | Token 过期未刷新 | 必须使用请求队列处理 401 |

## 6. Meegle 近期工作项
| ID | 标题 | 状态 |
|----|------|------|
| {id} | {title} | {status} |
```
