---
name: devflow-quick
description: DevFlow 快速需求。把需求描述直接作为输入，根据复杂度自动判断路径：极简改动（1-2个文件）直接编码，小需求跳过 design/plan 直接编码，复杂需求走完整流程。当用户说「devflow quick」「快速需求」「快速开始」或直接跟着需求描述时触发。
---

# devflow quick — 快速需求

**用途：** 将需求描述直接作为输入，根据复杂度自动判断执行路径，避免小改动走完整流程的浪费。

---

## 三条执行路径

分析完需求后，根据复杂度自动选择路径：

| 路径 | 适用场景 | 执行步骤 |
|------|---------|---------|
| **极简** | 改动 ≤ 2 个文件，逻辑显而易见（文案/配置/样式微调） | 分析 → **直接编码** |
| **快速** | 改动 3-5 个文件，思路清晰但有一定影响面 | 分析 → **内联方案** → 直接编码 |
| **完整** | 改动 > 5 个文件，或涉及新模块/接口设计/架构变更 | 分析 → 转交 `devflow design → plan → code` |

判断标准：
- CodeGraph 查到的影响符号 ≤ 3 个 → 极简
- CodeGraph 影响符号 4-10 个，且无新增接口 → 快速
- CodeGraph 影响符号 > 10 个，或需要新增接口/模块 → 完整

---

## 前置条件

- 若 `.devflow/` 不存在，自动触发 `devflow init` 后继续。
- `$ARGUMENTS` 不为空。

```
✗ 请在命令后附上需求描述。
  示例：devflow quick 修改登录页文案「立即登录」改为「登录」
```

---

## 输入

```
devflow quick 修改登录页文案「立即登录」改为「登录」
devflow quick 详情页右上角加分享按钮 https://figma.com/...
devflow quick 接入优惠券列表接口 https://yapi.example.com/...
```

---

## 执行步骤

### 1. 前置检查与工作项创建（静默完成）

检查 `.devflow/workspace.json`，不存在则自动执行 `devflow init`。

从描述推断 `type` / `slug` / `title`，生成 ID `{YYYYMMDD}-{slug}`，创建目录：

```
.devflow/work-items/{YYYYMMDD}-{slug}/
├── meta.json
├── context/
│   └── sanitized.md   ← 直接写入 $ARGUMENTS
├── spec/
│   └── requirement.md ← 分析后生成
├── progress.md
└── artifacts/
```

### 2. 立即处理资源链接

扫描 `$ARGUMENTS` 中的链接：
- **Figma 链接** → Figma Desktop MCP 立即读取（`get_figma_data` / `get_screenshot`）
- **YApi 链接** → WebFetch 立即读取接口详情

### 3. 分析 + 复杂度评估（合并完成）

执行以下分析，**全部收集后一次性输出**（不逐段打断）：

1. 从描述提取改动点、涉及模块
2. `devflow-cg explore "<模块名 关键词>"` 查现有实现和影响面
3. 检查是否需要新增/修改接口（无则跳过 YApi 搜索）
4. 统计 CodeGraph 影响符号数量，**判断路径**

若有歧义，在输出中汇总为一次追问，等用户回复后继续。

生成 `spec/requirement.md`（简化版，极简/快速路径只需：改动点描述 + 涉及文件 + 验收标准）。

---

### 路径 A：极简（≤ 2 文件，直接编码）

**跳过 `design` 和 `plan`**，直接编码。

输出确认后执行：
```
✅ 极简改动，直接编码
  涉及文件：{file1}, {file2}
  改动说明：{一句话}
  开始编码...
```

按 `devflow code` 的编码规范执行（质量门禁、lint/test 不跳过），完成后直接进 `devflow review`。

---

### 路径 B：快速（3-5 文件，内联方案后编码）

**跳过独立的 `design` 文档和 `plan` 文档**，在 `requirement.md` 末尾追加一个内联方案节：

```markdown
## 快速方案（inline）

**改动文件：**
| 文件 | 改动说明 |
|------|---------|
| com/xxx/XxxViewModel.kt | 新增状态字段 |
| res/layout/fragment_xxx.xml | 新增按钮控件 |

**关键逻辑：**
{一两句描述核心改动，不展开完整设计}

**验收：**
- [ ] {验收条件1}
- [ ] {验收条件2}
```

**输出确认：**
```
⚙️ 快速路径确认
  影响符号：{n} 个
  改动文件：{n} 个
  内联方案：已写入 requirement.md

  继续编码？(y / 查看方案详情 / 转完整流程)
```

用户确认后，按内联方案直接编码，完成后进 `devflow review`。

---

### 路径 C：完整（转交标准流程）

输出：
```
⚠️ 需求复杂度超出快速路径范围
  影响符号：{n} 个（超过阈值）
  原因：{涉及新增接口 | 影响面过大 | 需要架构决策}

  已完成需求分析，建议继续：
  → devflow design
```

`spec/requirement.md` 已生成，直接进 `devflow design` 即可，不需要重新分析。

---

### 4. 收尾

更新 `meta.json`：
- 极简/快速路径：`status → coding`，`stages.analyzed = true`，`stages.planned = true`
- 完整路径：`status → analyzing`，`stages.analyzed = true`

写入 `progress.md` Checkpoint。

可选：若 `meegle.projectKey` 已配置，询问是否同步 Meegle 工作项。

---

## 输出汇总

```
✅ 快速需求：{title}（{YYYYMMDD}-{slug}）
  路径：{极简 → 直接编码 | 快速 → 内联方案后编码 | 完整 → 转 devflow design}
  Figma：{已读取 | 无}
  接口：{已读取 n 个 | 无}
  影响符号：{n} 个
  歧义：{n 个已确认 | 无}
```
