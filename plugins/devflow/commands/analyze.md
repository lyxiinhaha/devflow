---
name: devflow-analyze
description: DevFlow 需求分析阶段。支持两种模式：（1）Intake Mode 流式模式——由 devflow start 后自动进入，每段输入立即解析、即时追问、实时写入文档；（2）Finalize 模式——用户说「就这些了」或「devflow analyze」时触发，做最终一致性检查并生成完整 spec。当用户说「需求分析」「分析需求」「devflow analyze」「就这些了」时也可独立触发。
---

# devflow analyze — 需求分析

**用途：** 支持边收录边分析的流式模式。`devflow start` 后自动进入 Intake Mode，每段输入立即解析、即时追问、实时写入文档；收到结束信号后执行最终一致性检查，生成完整 `spec/requirement.md`。

---

## 两种运行模式

| 模式 | 触发时机 | 行为 |
|------|---------|------|
| **Intake Mode（流式）** | `devflow start` 完成后自动进入 | 每段输入立即解析，即时追问，实时更新文档 |
| **Finalize 模式（收尾）** | 用户说「就这些了」/「完了」/「devflow analyze」 | 最终一致性检查，生成完整 spec，写入 Checkpoint |

---

## ⚠️ 最高级别禁令（全模式适用）

- ❌ 绝对禁止读取 `context/raw.md`，只能读取 `context/sanitized.md`
- ❌ 绝对禁止臆造需求文档中不存在的业务需求
- ❌ 绝对禁止自行设计技术方案或实现细节
- ❌ 歧义未经用户确认前，禁止视为最终结论
- ✅ 分析结论必须有明确来源（原文 / Figma 节点 / 接口定义 / 用户确认）

---

## Intake Mode（流式模式）

### 触发条件

`devflow start` 完成后自动激活。此后**每一条用户消息**都视为需求输入，立即执行以下流程。

退出条件：用户发送结束信号词（见 Finalize 模式触发词）。

---

### 每段输入的处理流程

收到一段输入后，立即按类型识别并处理：

#### A. 文字内容

1. **提取功能点**：识别明确的需求动词（支持/允许/禁止/展示/跳转/校验/上传/刷新…），形成功能点列表
2. **提取实体**：页面名、模块名、字段名、接口名、状态名——用于后续 CodeGraph 和接口文档交叉核验
3. **追加到 `context/sanitized.md`**：保留原文，追加到文件末尾，标注 `#N`
4. **实时更新 `spec/requirement.md`**：将提取的功能点归入对应章节
5. **即时追问**：发现以下任一情况，**当场追问**，不攒到最后：
   - 边缘情况缺失（失败态/空态/异常分支未描述）
   - 条件分支不完整（什么情况下 A，什么情况下 B）
   - 与已有内容矛盾
   - 涉及接口但无接口信息
   - 涉及 UI 但无设计稿

**回复格式：**
```
📥 #N 已解析
  功能点：{提取到的功能点列表}
  [⚠️ {即时追问}（有疑义时才出现）]
```

用户回答追问后：
```
📝 已记录：{答案摘要}
```

---

#### B. Figma 链接

识别规则：URL 包含 `figma.com/design/` 或 `figma.com/file/`

1. **立即读取**：优先使用 **Figma Desktop MCP**（`figma` 插件，已全局安装）读取节点内容

   ```
   get_figma_data(fileKey, nodeId)     # 读取节点结构和属性
   get_screenshot(fileKey, nodeId)     # 获取视觉截图（辅助理解布局）
   get_metadata(fileKey)               # 获取文件级元数据
   ```

   从 URL 解析 `fileKey`（路径第三段）和 `nodeId`（`node-id` 参数）

2. **提取并记录**：
   - 页面层级（页面、弹窗、Tab、底部面板）
   - 组件清单（可复用组件、自定义组件）
   - 所有交互状态（Normal / Loading / Empty / Error / Disabled）
   - 所有文案（按钮、标题、提示语、占位符）
   - 条件展示逻辑（哪些元素在什么条件下出现）
   - 布局约束（安全区域、键盘顶起、横竖屏）

3. **实时写入 `spec/requirement.md`** 的「UI 交互规范」章节

4. **与已有文字内容交叉核验**：
   - Figma 中有但文字需求未提及的元素 → 即时追问是否在本期范围
   - 文字需求提及但 Figma 中不存在的页面 → 即时追问

**回复格式：**
```
🔍 读取 Figma 中...
📥 #N 已解析
  页面：{页面清单}
  状态：{交互状态清单}
  文案：{关键文案}
  [⚠️ {交叉核验发现的问题，即时追问}]
```

**Figma Desktop MCP 不可用时（降级顺序）：**

1. **Framelink MCP**（`figma-developer-mcp`，项目 `.mcp.json` 中配置）：
   ```
   get_figma_data(fileKey, nodeId)
   ```
2. **均不可用**：记录链接，标注「待手动核验」，不阻塞流程：
   ```
   📥 #N Figma 链接已记录（MCP 不可用，分析阶段待手动核验）
     链接：{URL}
   ```

---

#### C. YApi / Apifox / 接口链接

识别规则：URL 包含 `yapi.`、`/interface/api/`、`apifox.com`、`/api/detail`

**① YApi WebFetch（首选）**

```
WebFetch: https://yapi.hszq8.com/api/interface/get?id={接口ID}
```
从 URL 中提取接口 ID（`/api/{id}` 路径段或 `id=` 参数）。

若用户只提供了项目链接（无具体接口 ID），先搜索：
```
WebFetch: https://yapi.hszq8.com/api/interface/list?project_id={pid}&page=1&limit=20
```
按接口路径或名称匹配，找到后读取接口详情。

**② Apifox MCP（降级）**

YApi 不可用时，使用 MCP 名「**API 文档**」：
```
search_api_by_keywords(keywords)
get_api_detail(apiId)
```

读取后提取并记录：
- 请求方法和路径
- 请求参数（字段名 / 类型 / 必填 / 说明 / 枚举值）
- 响应结构（字段名 / 类型 / 枚举值 / 默认值）
- 错误码列表

实时写入 `spec/requirement.md` 的「接口依赖」章节。

**交叉核验**：
- 接口字段与文字需求描述是否一致
- 接口有无客户端需要处理但未提及的字段或错误码

**回复格式：**
```
🔍 读取接口中...
📥 #N 已解析
  接口：{方法} {路径}
  关键字段：{字段摘要}
  [⚠️ {与需求文字的冲突或待确认项，即时追问}]
```

---

#### D. 图片 / 截图

识别规则：用户粘贴图片，或发送本地文件路径

1. 保存到 `artifacts/screenshot-N.{ext}`
2. 识别图片中的可见内容（页面名称、UI 元素、文案、状态）
3. 追加描述到 `context/sanitized.md`
4. 与已有文字/Figma 内容交叉核验

**回复格式：**
```
📥 #N 图片已保存（artifacts/screenshot-N.png）
  识别到：{可见内容描述}
  [⚠️ {与已有内容的差异，即时追问}]
```

---

#### E. 结束信号词（触发 Finalize）

识别以下任一表述，退出 Intake Mode，进入 Finalize 模式：
- `就这些了` / `就这些` / `完了` / `差不多了` / `没了`
- `开始分析` / `分析一下` / `analyze`
- `devflow analyze`

---

## Finalize 模式（收尾）

用户发出结束信号后执行，**不再解析新需求，只做归纳和检查**。

### 1. Figma 设计稿完整性检查

在进入一致性检查前，先确认 UI 相关需求是否有设计稿支撑。

**判定「涉及 UI 改动」的信号词**（出现任一即触发检查）：
页面 / 弹窗 / 底部面板 / 布局 / 组件 / 样式 / 交互 / 动画 / 颜色 / 字体 / 间距 / 图标 / 按钮 / 列表 / 导航

**检查逻辑（按优先级）：**

1. Intake 过程中已收到 Figma 链接并读取 → 已有设计稿，跳过
2. `artifacts/` 中有截图 → 已有视觉参考，跳过
3. 发现 UI 改动但以上均无 → **在此追问，不进入后续步骤**：

```
⚠️ 需求涉及 UI 改动，但未收到 Figma 设计稿。
   请提供以下任一后继续分析：
   · Figma 链接：https://www.figma.com/design/...
   · 设计稿截图（直接粘贴）
   · 若沿用现有样式无视觉变更，请确认「无 UI 变更」
```

收到后立即处理（同 Intake Mode 的 B 类型），补充写入 `spec/requirement.md` 的「UI 交互规范」章节，然后继续 Finalize 流程。

---

### 2. 最终一致性检查

扫描已收集的全部内容，检查：
- 文字需求 vs Figma 是否有遗漏或矛盾
- 文字需求 vs 接口定义是否有字段遗漏或类型冲突
- 各功能点是否都有对应的验收标准
- 边缘情况（空态/失败态/权限拒绝）是否覆盖

### 3. CodeGraph 代码现状核验 + 现有接口反查

#### 多根目录路由（执行查询前必须）

读取 `workspace.json` 的 `codegraph` 配置，确定查询策略：

- **单根项目**：直接在当前目录执行 `codegraph_explore`
- **多根项目（iOS CocoaPods / 多仓库）**：
  1. 先检查索引新鲜度（`codegraph status`），若检测到 `pod install` / `submodule update` 后未重建，提示用户先执行 `codegraph index` 再继续
  2. 查符号定义和组件内部实现 → cd 到该符号所在组件的 root 路径执行
  3. 查全局影响（谁调用了该符号）→ 在壳工程根目录（`roots[0].path`）执行
  4. 合并两次结果，完整影响面 = 组件内调用链 + 全局调用方

详细路由规则见 `references/codegraph-routing.md`。

提取所有页面名、模块名、接口名，按上述路由执行：
```
codegraph_explore("<提取的名词 空格分隔>")
```

识别出现有模块后，**主动反查该模块关联的接口**：

1. 从 CodeGraph 结果中提取现有模块的类名、Repository 名、Service 名
2. 用模块名/路径关键词在 YApi 中搜索关联接口：
   ```
   WebFetch: https://yapi.hszq8.com/api/interface/list_menu?project_id={pid}
   ```
   或按路径前缀搜索：
   ```
   WebFetch: https://yapi.hszq8.com/api/interface/list?project_id={pid}&page=1&limit=50
   ```
   筛选路径中包含模块关键词的接口（如 `/user/avatar`、`/profile/` 等）

3. 对命中的接口逐一读取详情，补充到 `spec/requirement.md` 的「接口依赖」章节：
   - 标注来源：`[来自 PRD]` 或 `[CodeGraph 反查]`
   - 重点关注：现有接口是否满足新需求，还是需要扩展字段

4. 将模块核验结论写入「现状背景核验」章节：
   - 涉及的现有模块/文件路径
   - 需要新增 vs 需要改造的部分
   - CodeGraph 反查到的现有接口清单

**YApi 不可用时**：降级为 Apifox MCP，或仅记录模块名称，标注「接口待手动核查」。

CodeGraph 不可用时：降级为 grep / find，注明。

### 4. 补充未回答的歧义

若有之前追问但用户未回答的问题，**在此汇总列出**，等待用户逐条确认后继续。

确认前禁止：自行假设 / 修改结论 / 生成最终版。

### 5. 生成完整 `spec/requirement.md`

将所有已解析内容整合为完整文档，必须包含以下章节：

| 章节 | 来源 |
|------|------|
| 背景与目标 | 文字需求 |
| 设计稿与参考链接 | 所有原始链接，一个不少 |
| 用户故事 | 文字需求 |
| 功能需求拆解 | 文字需求 + Figma 交叉 |
| UI 交互规范 | Figma 读取结果 |
| 接口依赖 | YApi/Apifox 读取结果 + CodeGraph 反查的现有接口 |
| 现状背景核验 | CodeGraph 核验结果 |
| 非功能需求 | 文字需求（无则写「暂无」） |
| 验收标准 | 各来源综合 |
| 歧义与待确认问题 | 整个 Intake 过程中未解决的问题 |

标记文档为「（最终版）」。

### 6. Context Checkpoint

将以下内容写入 `progress.md`：
- 关键业务规则和约束
- Figma 核心页面清单
- 接口列表（路径 + 关键字段）
- CodeGraph 涉及模块

更新 `meta.json`：`status → analyzing`，`stages.analyzed = true`。

### 7. 可选：Meegle 同步

若 `meta.json.linkedMeegleId` 存在，将需求摘要以评论形式同步到 Meegle 工作项。

---

## 输出（Finalize 完成后）

```
✅ 需求分析完成，文档已落盘。

资料来源：
  PRD：{n} 段已解析，{m} 个功能点
  Figma：{已读取 n 个节点 | 链接已记录待手动核验 | 无}
  接口文档：{Apifox n 个接口 | YApi 降级 | 仅文字描述}
  CodeGraph：{n 个符号已核验 | 手动降级}

歧义问题：{n} 个已在 Intake 过程中确认，{m} 个在 Finalize 时确认
已写入 Context Checkpoint。
Meegle 同步：{已同步 | 未配置}

下一步：使用 `devflow design` 开始技术设计。
```
