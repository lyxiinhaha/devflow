<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.8.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
  <img src="https://img.shields.io/badge/platform-Kiro-68d391?style=for-the-badge&labelColor=0d1829" alt="Kiro" />
</p>

<h1 align="center">DevFlow × Kiro 使用手册</h1>
<p align="center">从安装到第一个需求落地，10 分钟上手</p>

<br/>

<p align="center">
  <a href="#零devflow-能解决-kiro-的哪些痛点">为什么用</a> ·
  <a href="#一安装">安装</a> ·
  <a href="#二升级">升级</a> ·
  <a href="#三初始化项目">初始化</a> ·
  <a href="#四日常开发">日常开发</a> ·
  <a href="#五修复-bug">修复 Bug</a> ·
  <a href="#六可选集成">可选集成</a> ·
  <a href="#七常见问题">常见问题</a>
</p>

---

## 零、DevFlow 能解决 Kiro 的哪些痛点

Kiro 是以 Spec 驱动开发为核心设计理念的 AI IDE，比一般 AI 编码工具多了需求规格和设计文档的沉淀机制。但在实际项目里，仍然有几个问题需要 DevFlow 来补全：

---

**痛点 1：Spec 是静态快照，跑起来的代码是动态调用图**

Kiro 的 spec 文件记录了需求和设计意图，但当你问"这个函数改了会影响谁"，spec 里没有答案——代码调用关系不在 spec 里。

DevFlow 的解法：
- `devflow design` 在技术方案生成前，先用 CodeGraph 计算**爆炸半径**——精确到符号级别，哪些函数、哪些接口会受牵连，列出来再动手
- `devflow review` 用 CodeGraph 验证影响面，发现超出预期的改动直接阻断合并

---

**痛点 2：Steering File 只告诉 AI 怎么做，不知道为什么**

Kiro 的 Steering 能注入规则，但缺少"这段历史踩过什么坑"的上下文。同一类 Bug 换个项目就可能重现。

DevFlow 的解法：
- `devflow fix` 修复后强制 `retrospect`，将根因和修复方案提炼为**经验卡**入库
- `devflow plan` 生成任务清单时自动召回相关经验卡，历史踩过的坑提前标注

---

**痛点 3：Agent Hooks 门禁难以配置，影响范围不可见**

Kiro 支持 Agent Hooks，但配置高风险改动的门禁需要手动定义触发条件。改一个被十几个地方引用的函数，只有靠经验才能判断需不需要停下来确认。

DevFlow 的解法：
- `devflow design` 自动评估 HIGH / CRITICAL 级别改动并触发确认门禁，CodeGraph 出数据，AI 做判断，不靠经验猜测
- `devflow code` 内置 L0 安全规则（禁止直接 `rm -rf`、禁止无条件覆盖生产配置等），与 Kiro Hooks 互补

---

**痛点 4：跨会话后 Spec 和实际代码可能已经不同步**

需求在进行中变更是常态。Spec 写完后代码改了，或者代码改了 Spec 没同步，时间长了就不知道以当前 spec 为准还是以代码为准。

DevFlow 的解法：
- 每个工作项有 `progress.md`（Checkpoint），记录每次状态跃迁和决策
- `devflow change` 执行时同步评估爆炸半径、回退受影响任务状态、写入回归义务，spec 和代码的偏差显式化

---

**痛点 5：Spec-Driven 流程缺少经验的反向输入**

Spec 由人来写，经验无法自动沉淀回下一个 Spec。每次写新需求时，历史踩的坑只能靠记忆。

DevFlow 的解法：
- 三层知识体系：**项目规则**（project-rules.md）→ **经验卡**（bug-experience-cards.csv）→ **历史案例**
- `devflow knowledge distill` 将积累的经验卡提炼为项目级规则，`plan` / `code` / `review` 自动注入

---

| Kiro 痛点 | DevFlow 对应能力 |
|-----------|----------------|
| Spec 无法感知运行时调用关系 | `design`（爆炸半径）+ `review`（影响面验证） |
| 经验无法沉淀到 Steering | `fix` + `retrospect`（经验卡）+ `knowledge distill`（规则提炼） |
| 高风险改动门禁难以配置 | `design`（CodeGraph 自动分级）+ L0 安全规则 |
| 跨会话 spec/代码不同步 | `continue`（Checkpoint）+ `change`（回归传播） |
| 需求知识不回流 | 三层知识体系自动召回 |

> 完整的 SDLC 闭环流程图（含 CodeGraph 调用节点标注）请见 [主 README → 关于项目](./README.md#关于项目)。

---

## 一、安装

### 前置要求

- **Kiro** 已安装（[下载](https://kiro.dev)）
- **Node.js 18+** — CodeGraph 依赖，`devflow init` 会自动安装，确保 Node.js 可用即可

### 一行命令安装

在**项目根目录**下运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --platform kiro
```

脚本会自动检测到 Kiro 平台，交互式引导你完成：

1. **平台确认** — 检测到 `.kiro/` 目录后直接确认，无需手动选择
2. **文件安装** — 20 个命令文件、Steering File、配置模板全部就位
3. **基础配置** — 可选填写 YApi 域名、Meegle 项目 Key，直接回车跳过

安装过程示例：

```
DevFlow v3.8.0 — AI 研发工作流
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  模式：远程安装（从 GitHub 下载）

  检测到平台：kiro
  使用此平台？[Y/n] Y

  平台：kiro
  目录：/path/to/your-project

正在安装命令文件...
  ✓ 命令文件 → .devflow/commands/ （20 个）
  ✓ 配置模板 → .devflow/config/
  ✓ workspace.json 已初始化

正在安装平台适配器...
  ✓ Kiro Steering → .kiro/steering/devflow.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  基础配置（可选，直接回车跳过）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [1/3] YApi 接口文档
  YApi 域名（如 yapi.example.com）：

  [2/3] Meegle（飞书项目）
  Meegle 项目 Key（如 PROJ）：

  [3/3] 专项验收清单 Skill
  Skill 名称（如 my-acceptance-checklist）：

  ✓ .gitignore 已追加 DevFlow 条目

✅ DevFlow 安装完成！

  下一步：
  1. 用 Kiro 打开项目，输入：
     devflow init
  DevFlow Steering 文件已写入 .kiro/steering/devflow.md，Kiro 会自动加载。
```

安装完成后，用 Kiro 打开项目，输入 `devflow init`——技术栈检测、CodeGraph 索引构建、Review Skill 生成会在 init 过程中完成。

---

## 二、升级

在项目目录执行一行命令：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --update
```

脚本会自动完成：

- 从 GitHub 拉取最新命令文件
- 覆盖 `.devflow/commands/` 下的所有命令文件
- 覆盖 `.devflow/config/` 下的配置模板
- 覆盖 `.kiro/steering/devflow.md` 适配器文件
- **不会覆盖** `.devflow/workspace.json`（你的本地配置）

---

## 三、初始化项目

安装完成后，用 Kiro 打开你的项目，在 AI 对话框中输入：

```
devflow init
```

AI 会自动引导你完成以下配置：

**1. 技术栈检测**（自动完成，无需操作）

AI 扫描项目文件识别技术栈，生成项目画像，保存到 `.devflow/devflow-profile.md`。

**2. CodeGraph 索引确认**

根据项目结构配置索引策略（单仓库 / 多仓库 / iOS 多 Pod 等）。

**3. Review Skill 配置（可跳过）**

询问是否生成专项代码审查规范。直接回车跳过，后续使用通用规范。

**4. 外部集成配置（可全部跳过）**

逐一询问 YApi / Meegle 地址，不用这些服务直接回车跳过。

**初始化完成后的输出示例：**

```
✅ DevFlow 初始化完成！

  技术栈：TypeScript · Vue 3 · Node.js
  CodeGraph：已建立索引（单根）
  Review Skill：devflow-review-frontend（已生成）
  YApi：未配置
  Meegle：未配置

现在可以使用 devflow start 创建第一个需求。
```

---

## 四、日常开发

### 开发一个新功能

**标准流程（完整需求）：**

```
devflow start 用户头像上传 支持裁剪和预览
```

AI 创建工作项后，依次执行：

```
devflow analyze
```

`devflow analyze` 进入**边录边析模式**——输入命令后，把你手头的需求内容直接贴进来就行，可以是：

- PRD 文字段落（直接粘贴）
- 截图（Kiro 支持直接粘贴图片）
- Figma 链接（AI 自动读取设计稿）
- YApi / 接口文档链接（AI 自动读取接口定义）
- 以上任意组合，分多次粘贴也可以

AI 边接收边解析，最后追问歧义点，生成 `spec/requirement.md`。确认无误后，继续下一步：

```
devflow design      # 技术设计：爆炸半径评估、生成设计文档（时序图/接口签名/验收清单）
devflow estimate    # 工作量估算
devflow plan        # 任务拆解：生成 tasks.md
devflow code        # 编码执行：按任务逐项实现，完成后自动编译验证
devflow review      # 代码审查：专项 Skill 或通用四维度审查，CRITICAL 阻断合并
devflow retrospect  # 复盘：经验入库，关闭工作项
```

---

**快速需求（小改动，一条命令）：**

适合文案修改、样式调整、接入已有接口等影响范围小的需求：

```
devflow quick 详情页右上角加分享按钮
devflow quick 登录按钮文案「立即登录」改为「登录」
devflow quick 接入优惠券列表接口 https://yapi.example.com/project/1/interface/api/123
```

AI 根据影响范围自动选择路径：

| 影响范围 | 执行路径 | 你要做的 |
|---------|---------|---------|
| ≤ 2 个文件 | 直接编码 | 确认后等待完成 |
| 3–10 个符号 | 内联方案 + 编码 | 确认方案后等待完成 |
| > 10 个符号 | 转 `devflow design` | 走完整流程 |

---

### 中途暂停与恢复

关闭 Kiro 或开启新对话后，输入：

```
devflow continue
```

AI 读取 Checkpoint，恢复上次进度，展示当前工作项状态和待完成任务。

---

### 并行多个需求

同时进行多个需求时，用 `switch` 切换焦点：

```
devflow list          # 查看所有活跃工作项
devflow switch        # 切换到另一个工作项
```

---

## 五、修复 Bug

`devflow fix` 支持三种输入方式，选最方便的：

**方式 1：直接描述 Bug（最简单，无需任何配置）**

```
devflow fix 点击提交按钮后页面白屏，控制台报 TypeError: Cannot read properties of null reading 'id'
```

```
devflow fix 用户登录后跳转到首页，但顶部导航栏显示未登录状态，刷新才恢复正常
```

**方式 2：Meegle 工作项链接（需配置 Meegle，见可选集成）**

```
devflow fix https://project.feishu.cn/xxx/issue/12345678
```

**方式 3：Meegle 工作项 ID**

```
devflow fix 12345678
```

---

**AI 执行的四阶段分析：**

```
Stage 1：入口定位     → CodeGraph 定位 Bug 触发的代码入口
Stage 2：调用链追踪   → 从入口追踪到问题根源的完整路径
Stage 3：爆炸半径评估 → 确认修复方案不会引入新问题
Stage 4：原子修复     → 最小化修改，生成修复清单
```

修复完成后 AI 会暂停，等你手动验证，确认无误后提交——这是 DevFlow 的**人工验证门禁**，防止 AI 自动提交未经验证的修复。

---

## 六、可选集成

这些都是可选的，不配置也能完整使用 DevFlow，只是对应功能降级处理。

### CodeGraph MCP

DevFlow 依赖 CodeGraph 做爆炸半径分析和调用链追踪。Kiro 原生支持 MCP 服务器，在 Kiro 的 MCP 配置中添加：

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "codegraph",
      "args": ["mcp"]
    }
  }
}
```

`devflow init` 执行时会自动检测 CodeGraph 是否可用，并引导完成安装和索引构建。跳过 CodeGraph 也能使用 DevFlow，但 `design`（爆炸半径评估）、`fix`（根因分析）、`review`（影响面验证）等命令会降级，分析精度明显下降。对于 600 文件以上的项目强烈建议安装。

### Meegle（飞书项目管理）

配置后 `devflow fix` 可直接读取 issue 详情，工作项状态自动同步飞书。

```bash
# 安装 Meegle CLI
npm install -g @meego/cli

# 登录授权
meegle auth login
```

然后重新执行 `devflow init`，会自动检测并配置。

---

### YApi / Apifox（接口文档）

配置后 `devflow analyze` 会自动读取接口定义，无需手动粘贴链接。

手动编辑 `.devflow/workspace.json`：

```json
{
  "integrations": {
    "yapiHost": "yapi.your-company.com"
  }
}
```

> 没有配置 YApi 时，直接在对话里粘贴完整的 YApi 链接也有效——AI 会即时读取，无需提前配置。

---

### Figma

配置后 `devflow analyze` 收到 Figma 链接时自动读取设计稿。

在 Kiro 的 MCP 配置中添加 Figma MCP 服务器，或安装 [Framelink MCP](https://github.com/sonnylazuardi/cursor-talk-to-figma-mcp)。

---

## 七、常见问题

**Q：输入 `devflow start` 后 AI 说"找不到命令文件"怎么办？**

A：检查 `.devflow/commands/` 目录是否存在。如果没有，重新运行安装脚本：
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --platform kiro --dir .
```

---

**Q：Kiro Steering File 会在每次对话都加载吗？**

A：会。`.kiro/steering/devflow.md` 配置了 `inclusion: always`，每次打开 Kiro 对话都会自动加载，不需要手动触发。

---

**Q：DevFlow 和 Kiro 的 Spec 文件有什么关系？**

A：两者互补，不冲突。Kiro 的 `.kiro/specs/` 是需求和设计意图的静态快照；DevFlow 的 `.devflow/work-items/` 是带状态机的执行记录（当前阶段、任务清单、经验召回、开放问题）。你可以只用其中一套，也可以同时用——`devflow analyze` 生成的 `requirement.md` 和 `devflow design` 生成的 `design.md` 与 Kiro Spec 格式兼容，可以手动复制对齐。

---

**Q：CodeGraph 索引多久需要更新一次？**

A：CodeGraph 通过 Git hooks 在每次 commit 后自动增量更新，通常不需要手动维护。如果手动大量修改文件后未 commit，可以执行：
```bash
codegraph update
```

---

**Q：能不能不用 CodeGraph？**

A：可以，DevFlow 不强依赖 CodeGraph。跳过 CodeGraph 时，`design`（爆炸半径评估）、`fix`（根因分析）、`review`（影响面验证）等命令会降级，改为基于 Kiro 内置代码索引做静态分析，精度较低。对于 600 文件以上的项目强烈建议安装。

手动安装：
```bash
npm install -g @colbymchenry/codegraph
codegraph init      # 在项目根目录构建索引
codegraph install   # 注册为 MCP
```

---

**Q：`.devflow/` 目录应该提交到 git 吗？**

A：命令文件可以提交（`.devflow/commands/`），但工作项数据不应提交。安装脚本已在 `.gitignore` 中加入以下条目：
```
.devflow/workspace.json
.devflow/work-items/
.codegraph/
```

---

**Q：团队多人使用时如何同步 Review 规范？**

A：使用 `devflow sync` 命令，将团队公共的 skills / agents 同步到当前项目：
```
devflow sync
```
具体配置方式见 `plugins/devflow/commands/sync.md`。

---

<p align="center">遇到问题请提交 <a href="../../issues">GitHub Issue</a></p>
<p align="center">Made with intent by <strong>Yeesin</strong></p>
