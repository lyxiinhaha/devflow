<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.3.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
  <img src="https://img.shields.io/badge/platform-Cursor-b794f4?style=for-the-badge&labelColor=0d1829" alt="Cursor" />
</p>

<h1 align="center">DevFlow × Cursor 使用手册</h1>
<p align="center">从安装到第一个需求落地，10 分钟上手</p>

<br/>

<p align="center">
  <a href="#一安装">安装</a> ·
  <a href="#二升级">升级</a> ·
  <a href="#三初始化项目">初始化</a> ·
  <a href="#四日常开发">日常开发</a> ·
  <a href="#五修复-bug">修复 Bug</a> ·
  <a href="#六可选集成">可选集成</a> ·
  <a href="#七常见问题">常见问题</a>
</p>

---

## 一、安装

### 前置要求

- **Cursor** 已安装（[下载](https://www.cursor.com)）
- **Node.js 18+** — CodeGraph 依赖，`devflow init` 会自动用 npm 安装 CodeGraph，确保 Node.js 可用即可
- **Git** — 用于克隆仓库

### 第一步：克隆 DevFlow 仓库

```bash
git clone https://github.com/lyxiinnaha/devflow.git
```

### 第二步：运行安装脚本

```bash
cd devflow
bash install.sh --platform cursor --dir /path/to/your-project
```

将 `/path/to/your-project` 替换为你的项目根目录，例如：

```bash
bash install.sh --platform cursor --dir ~/code/my-app
```

脚本会自动完成：

- 将 20 个命令文件复制到 `your-project/.devflow/commands/`
- 写入 Cursor Rules 文件 `your-project/.cursor/rules/devflow.mdc`
- 初始化 `your-project/.devflow/workspace.json`
- 更新 `your-project/.gitignore`

安装完成后，用 Cursor 打开项目，输入 `devflow init`——CodeGraph 的安装和索引构建会在 init 过程中自动完成。

---

## 二、升级

安装脚本会在项目的 `.devflow/.devflow-install.json` 中记录安装来源。后续升级只需两步：

**第一步：拉取 DevFlow 仓库最新代码**

```bash
cd /path/to/devflow   # 你当初 clone 的目录
git pull
```

**第二步：在项目目录执行更新**

```bash
bash /path/to/devflow/install.sh --update --dir /path/to/your-project
```

脚本会自动完成：

- `git pull` 拉取最新命令文件
- 覆盖 `.devflow/commands/` 下的所有命令文件
- 覆盖 `.devflow/config/` 下的配置模板
- 覆盖 `.cursor/rules/devflow.mdc` 适配器文件
- **不会覆盖** `.devflow/workspace.json`（你的本地配置）

> 安装时脚本末尾会打印完整的更新命令，直接复制备用即可。

---

## 三、初始化项目

安装完成后，用 Cursor 打开你的项目，在 AI 对话框中输入：

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
- 截图（Cursor 支持直接粘贴图片）
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

关闭 Cursor 或开启新对话后，输入：

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

在 Figma 桌面客户端安装官方 MCP 插件，Cursor 会自动识别。降级方案：安装 [Framelink MCP](https://github.com/sonnylazuardi/cursor-talk-to-figma-mcp)。

---

## 七、常见问题

**Q：输入 `devflow start` 后 AI 说"找不到命令文件"怎么办？**

A：检查 `.devflow/commands/` 目录是否存在。如果没有，重新运行安装脚本：
```bash
bash /path/to/devflow/install.sh --platform cursor --dir .
```

---

**Q：Cursor Rules 是否会在每次对话都加载？**

A：会。`.cursor/rules/devflow.mdc` 配置了 `alwaysApply: true`，每次打开 Cursor 对话都会自动加载，不需要手动触发。

---

**Q：CodeGraph 索引多久需要更新一次？**

A：CodeGraph 通过 Git hooks 在每次 commit 后自动增量更新，通常不需要手动维护。如果手动大量修改文件后未 commit，可以执行：
```bash
codegraph update
```

---

**Q：能不能不用 CodeGraph？**

A：`devflow init` 会自动安装 CodeGraph，通常不需要手动干预。如果安装失败，可以手动执行：
```bash
npm install -g @colbymchenry/codegraph
codegraph init      # 在项目根目录构建索引
codegraph install   # 注册为 MCP
```
跳过 CodeGraph 也可以用 DevFlow，但 `design`（爆炸半径评估）、`fix`（根因分析）、`review`（影响面验证）等命令会降级，分析精度明显下降。对于 600 文件以上的项目强烈建议安装。

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
