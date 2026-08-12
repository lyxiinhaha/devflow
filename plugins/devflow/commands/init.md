---
name: devflow-init
description: DevFlow 工作区初始化。检查并配置 CodeGraph 与 Meegle，自动检测技术栈（Android/iOS/KMP/Vue/React/Spring Boot/Go/Node.js 等任意栈），生成技术栈画像文档，建立 .devflow/ 目录结构，确认安全分级。当用户说「初始化 devflow」「devflow init」「初始化工作流」或在新项目首次使用 DevFlow 时触发。
---

# devflow init — 初始化工作区

**用途：** 在当前项目首次使用 DevFlow，建立 `.devflow/` 目录结构，**自动检测技术栈并生成项目画像**，配置 CodeGraph 与 Meegle，写入 `.gitignore`，确认安全分级。同一项目只需执行一次；`devflow start` 检测到未初始化时会自动触发本命令。

---

## 前置条件

- 必须在项目根目录执行。若当前目录不是根目录（无 README、构建配置文件、包管理文件或源码目录），必须提示用户切换目录后再继续，不得猜测。

---

## 执行步骤

### 1. 根目录校验

基于以下任一特征判断是否为项目根目录：README.md、package.json、build.gradle、Cargo.toml、pom.xml、Makefile、Podfile、*.xcodeproj、src/ 目录存在。

不满足时输出：
```
✗ 当前目录不像项目根目录。
  请切换到项目根目录后重新执行 devflow init。
```

### 2. 技术栈检测与项目画像

**自动扫描特征文件，识别技术栈，输出项目画像。** 这是 init 最核心的一步，结果决定后续 CodeGraph 索引策略、代码审查 skill 选择、编译验证命令等所有下游行为。

#### 2a. 特征文件扫描

按下表逐类扫描，**一个项目可同时命中多个分类**（如 KMP 同时命中 Android + iOS + Kotlin）：

| 分类 | 特征文件 / 目录 | 进一步识别 |
|------|----------------|------------|
| **Android** | `build.gradle` / `build.gradle.kts` + `AndroidManifest.xml` | `apply plugin: 'com.android.application'` → 壳工程；`library` → 库模块 |
| **iOS** | `*.xcodeproj` / `*.xcworkspace` / `Podfile` | 有 `Podfile` → CocoaPods；有 `Package.swift` → SPM |
| **KMP（Kotlin Multiplatform）** | `build.gradle.kts` + `kotlin("multiplatform")` | 同时有 Android + iOS 特征 |
| **Flutter** | `pubspec.yaml` + `lib/` + `flutter:` section | `android/` `ios/` 子目录 → 多端壳 |
| **React / Next.js** | `package.json` + `react` in deps | `next.config.*` → Next.js；`vite.config.*` → Vite；`webpack.config.*` → Webpack |
| **Vue / Nuxt** | `package.json` + `vue` in deps | `nuxt.config.*` → Nuxt；否则 → Vue CLI / Vite |
| **Angular** | `angular.json` / `package.json` + `@angular/core` | — |
| **Node.js 服务端** | `package.json` + `express` / `koa` / `fastify` / `nestjs` in deps | `src/app.ts` / `src/index.js` → 入口 |
| **Spring Boot / Java** | `pom.xml` 或 `build.gradle` + `spring-boot` | `src/main/java/` / `src/main/kotlin/` → 源码根 |
| **Go** | `go.mod` | `main.go` → 可执行程序；无 `main.go` → 库 |
| **Python** | `requirements.txt` / `pyproject.toml` / `setup.py` | `Django` / `Flask` / `FastAPI` in deps → Web 框架；`Jupyter` → 数据科学 |
| **Rust** | `Cargo.toml` | `[lib]` / `[[bin]]` → 库 / 可执行 |
| **其他** | `Makefile` / `CMakeLists.txt` / `*.csproj` | C/C++ / C# / .NET |

对每个命中的分类，进一步检测：

**数据库 / 存储**（扫描依赖声明文件和配置文件关键词）：

| 关键词来源 | 识别目标 |
|-----------|---------|
| `pom.xml` / `build.gradle` / `package.json` / `requirements.txt` / `go.mod` / `Cargo.toml` | MySQL、PostgreSQL、MongoDB、Redis、SQLite、Elasticsearch、Cassandra、InfluxDB、DynamoDB |
| `application.yml` / `application.properties` / `.env` / `docker-compose.yml` | 数据库连接字符串、端口（3306/5432/27017/6379 等） |

**基础设施 / 部署**：

| 特征文件 | 识别目标 |
|---------|---------|
| `Dockerfile` / `docker-compose.yml` | Docker 容器化 |
| `k8s/` / `helm/` / `*.yaml` with `kind: Deployment` | Kubernetes |
| `.github/workflows/` | GitHub Actions CI |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `terraform/` / `*.tf` | Terraform IaC |

**测试框架**（从依赖声明识别）：
JUnit / Espresso / XCTest / Jest / Vitest / Cypress / Playwright / pytest / Go test / RSpec 等

---

#### 2b. 多仓库 / 多模块结构识别

在技术栈检测基础上，额外识别代码组织方式：

**Android / KMP 含 submodules**：
```bash
ls .gitmodules 2>/dev/null && cat .gitmodules | grep path
```
有 submodules → 单根索引，记录 `rebuildTriggers: ["submodule update"]`

**iOS CocoaPods 含本地 path Pod**：
```bash
grep -E "pod.*:path\s*=>" Podfile | head -20
```
有本地 path Pod → 多根索引，询问用户是否为各 Pod 建立独立索引：
```
检测到本地 path Pod：
  1. ../HSAccountKit  (pod 'HSAccountKit', :path => '../HSAccountKit')
  2. ../HSTradeKit    (pod 'HSTradeKit',   :path => '../HSTradeKit')

是否为它们各自初始化 CodeGraph 索引？（推荐：是）
```

**前端 Monorepo**：
```bash
ls packages/ apps/ 2>/dev/null
cat package.json | grep workspaces
```
有 workspaces / packages/ → Monorepo，列出各子包

**后端多模块**：`pom.xml` 含 `<modules>` / `settings.gradle` 含 `include(":module")` → 模块化工程

**多仓库（完全独立）**：用户明确告知，或根目录存在 `.devflow/multi-repo.json`（上次配置留存）：
```
当前项目是否依赖其他本地仓库的源码（如共享库、平台层、基础组件）？
如果是，请提供其他仓库的本地路径（一行一个，直接回车跳过）：
```

---

#### 2c. 生成技术栈画像

将检测结果写入 `.devflow/devflow-profile.md`，并在 `workspace.json` 中保存结构化摘要：

**`.devflow/devflow-profile.md` 格式：**

```markdown
# 项目技术栈画像

> 由 `devflow init` 自动生成，可手动补充修正。

## 基本信息

| 项 | 值 |
|----|----|
| 项目名 | {从 package.json/pom.xml/build.gradle/README 提取} |
| 检测时间 | {ISO 时间戳} |
| 仓库结构 | {单仓库 | Monorepo | 多仓库 | 壳工程+submodules | iOS+本地Pod} |

## 技术栈

| 层级 | 技术 | 版本（如可识别） |
|------|------|----------------|
| 语言 | {Kotlin / Swift / TypeScript / Java / Go / Python / ...} | {版本} |
| 框架 | {Android SDK / SwiftUI / UIKit / Vue 3 / React 18 / Spring Boot / ...} | {版本} |
| 构建工具 | {Gradle / Maven / Vite / Webpack / CocoaPods / SPM / ...} | {版本} |
| 测试框架 | {JUnit / XCTest / Jest / pytest / ...} | {版本} |

## 数据库 / 存储

| 类型 | 组件 | 用途（如可识别） |
|------|------|----------------|
| 关系型 | {MySQL 8.0 / PostgreSQL 15 / SQLite / ...} | {用户数据 / 业务库 / 本地缓存} |
| NoSQL | {MongoDB / Redis / Elasticsearch / ...} | {文档存储 / 缓存 / 全文搜索} |
| 消息队列 | {Kafka / RabbitMQ / ...} | — |
| 对象存储 | {OSS / S3 / ...} | — |

（未检测到数据库依赖时本节省略）

## 基础设施 / 部署

| 组件 | 说明 |
|------|------|
| 容器化 | {Docker / Docker Compose | 未检测到} |
| 编排 | {Kubernetes / Helm | 未检测到} |
| CI/CD | {GitHub Actions / GitLab CI / Jenkins | 未检测到} |
| IaC | {Terraform / CDK | 未检测到} |

## CodeGraph 索引策略

| 根目录 | 覆盖范围 | 重建触发条件 |
|--------|---------|------------|
| {路径} | {描述} | {条件} |

查询指南：{根据仓库结构生成，如"单根直接查；多根时组件内查本地Pod，全局影响查壳工程根目录"}

## 编译验证命令

| 平台 | 命令 |
|------|------|
| {Android} | `./gradlew compileDebugSources` |
| {iOS} | `xcodebuild -workspace *.xcworkspace -scheme <Scheme> -sdk iphonesimulator build -configuration Debug` |
| {前端} | `tsc --noEmit` 或 `vite build --mode check` |
| {后端} | `mvn compile -q` 或 `./gradlew compileJava` 或 `go build ./...` |

## 代码审查 Skill 映射

| 触发条件 | Skill |
|---------|-------|
| diff 含 Android/KMP 代码 | `sahm-code-review-android` |
| diff 含 iOS/Swift/ObjC | `sahm-code-review-ios` |
| diff 含 Vue/React/TS | {通用审查 | 项目专项 skill} |
| diff 含 Java/Kotlin 后端 | {通用审查 | 项目专项 skill} |

## 注意事项 / 特殊约定

- {检测过程中发现的特殊结构，如：Monorepo apps/web 和 apps/api 共用 packages/ui}
- {版本特殊性，如：使用 Vue 2，不是 Vue 3}
- {未识别的部分，需用户手动补充}
```

**`workspace.json` 中增加 `techStack` 节点（结构化，供其他命令程序化读取）：**

```json
{
  "techStack": {
    "languages": ["Kotlin", "Swift"],
    "frameworks": ["Android SDK", "SwiftUI"],
    "buildTools": ["Gradle 8.x", "CocoaPods 1.x"],
    "databases": ["MySQL", "Redis"],
    "infrastructure": ["Docker", "GitHub Actions"],
    "testFrameworks": ["JUnit 5", "XCTest"],
    "repoStructure": "shell+submodules | monorepo | multi-root | single",
    "compileCommands": {
      "android": "./gradlew compileDebugSources",
      "ios": "xcodebuild -workspace *.xcworkspace -scheme <Scheme> -sdk iphonesimulator build",
      "shared": "./gradlew :shared:compileKotlinAndroid"
    }
  },
  "codegraph": {
    "strategy": "single-root | multi-root",
    "roots": [...],
    "queryGuide": "..."
  }
}
```

---

**检测不确定时的处理原则：**

- 识别到技术栈但版本不确定 → 写 `未知版本`，不猜测
- 依赖声明中存在某组件但配置文件无连接信息 → 注明"依赖中存在，连接配置未确认"
- 完全无法识别某层技术 → 在画像中留空并注明"未检测到，请手动补充"
- 检测完成后将画像摘要展示给用户，明确询问："以上技术栈信息是否准确？如有遗漏或错误，请告知，我会更新画像。"

---

### 3. 执行 CodeGraph 索引

```bash
codegraph --version
```

- **已安装**：按步骤 2b 确定的索引策略执行 `codegraph init`（各根目录依次执行）。
  - 源码文件 > 500 个的根目录：后台运行，不阻塞后续流程。
  - 执行 `codegraph install` 注册 MCP（仅需执行一次）。
  - 执行 `codegraph status` 验证。
- **未安装**：`npm install -g @colbymchenry/codegraph`，安装后同上。
- **用户明确跳过**：不执行任何 CodeGraph 命令。
- **安全禁令**：不得修改 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 已有内容（只能追加 CodeGraph 维护规则）。

### 4. 生成 CodeGraph 多根目录查询规则（CLAUDE.md 注入）

**多仓库或多根索引场景的关键步骤。** 将查询规则写入当前项目的 `CLAUDE.md`（若不存在则创建），让后续所有 AI 会话都知道如何跨仓查询。单根单仓库可跳过本步。

```markdown
## CodeGraph 多根目录查询规则

本项目采用{单根 | 多根}索引策略，索引分布如下：

{根据步骤 2 的检测结果动态生成，例如：}

- 壳工程：{绝对路径}（覆盖：壳工程源码 + Pods/ 源码）
- 本地 Pod HSAccountKit：{绝对路径}（覆盖：本地联调最新源码）

查询流程：
1. 查组件内部调用链 → cd 到组件目录执行 codegraph_explore / codegraph_impact
2. 查全局影响（谁调用了该组件）→ 在壳工程根目录执行 codegraph_impact
3. 跨仓查询时，将两次结果合并得出完整影响面

CodeGraph 索引维护：
- 执行 pod install / pod update 后：cd {壳工程} && codegraph index
- 本地 Pod 修改后：cd {pod路径} && codegraph sync
- submodule update 后：cd {壳工程} && codegraph index
```

### 5. 检查 Meegle

```bash
meegle --version
```

- **已安装**：`meegle auth status` 验证；已授权则继续，未授权则 `meegle auth login`。
- **未安装**：提示安装；Meegle 为可选，用户跳过不影响后续流程。
- 授权成功后 `meegle user me` 验证，输出当前用户名。

### 6. 建立 `.devflow/` 目录结构

将插件包 `assets/config/` 复制到 `.devflow/config/`，`assets/templates/` 复制到 `.devflow/config/templates/`。

初始化 `workspace.json`（合并步骤 2 生成的 codegraph 配置）：
```json
{
  "currentWorkItem": null,
  "meegle": {
    "projectKey": null,
    "defaultWorkItemType": null
  },
  "codegraph": {
    "strategy": "single-root | multi-root",
    "roots": [...],
    "queryGuide": "..."
  }
}
```

### 7. 写入 `.gitignore`

确保以下条目存在（不重复写入）：

```gitignore
# DevFlow workspace (local only)
.devflow/

# CodeGraph index (local only)
.codegraph/
```

### 8. 交互式配置

1. **安全分级确认**：展示默认值，请求用户确认并写入。
2. **Meegle 空间配置**（可选）：若有，执行 `meegle project search` 获取 `project_key` 写入 `workspace.json`。

---

## 禁令

- ❌ 禁止覆盖 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 已有内容，只能追加
- ❌ 用户跳过 CodeGraph 时，禁止执行任何 CodeGraph 命令
- ❌ 禁止在非项目根目录执行初始化

---

## 输出

```
✅ DevFlow 初始化完成！

  根目录：{path}

  ── 技术栈画像 ────────────────────────────────
  语言：{Kotlin + Swift | TypeScript | Java | Go | Python | ...}
  框架：{Android SDK + SwiftUI | Vue 3 | Spring Boot | ...}
  构建：{Gradle 8.x | Maven | Vite + pnpm | CocoaPods | ...}
  数据库：{MySQL + Redis | PostgreSQL | MongoDB | 未检测到}
  基础设施：{Docker + GitHub Actions | K8s | 未检测到}
  测试：{JUnit 5 + XCTest | Jest + Cypress | pytest | 未检测到}
  仓库结构：{单仓库 | Monorepo（apps/web, apps/api） | 壳工程+submodules | iOS+本地Pod}

  完整画像：.devflow/devflow-profile.md

  ── CodeGraph ─────────────────────────────────
  索引策略：{单根 | 多根}
    {path1}：{已建立索引 | 后台执行中 | 已跳过}
    {path2}：{已建立索引 | 已跳过}（本地 Pod）
  多根查询规则：{已写入 CLAUDE.md | 单根无需注入}

  ── 配置 ──────────────────────────────────────
  Meegle：{已连接（用户：xxx）| 未配置}
  安全分级：{L0 | L1 | L2}
  .gitignore：已更新

现在可以使用 `devflow start` 创建第一个需求，或 `devflow fix` 修复 Bug。
```
