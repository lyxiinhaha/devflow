---
name: devflow-init
description: DevFlow 工作区初始化。检查并配置 CodeGraph 与 Meegle，自动检测技术栈（Android/iOS/KMP/Vue/React/Spring Boot/Go/Node.js 等任意栈），生成技术栈画像文档，建立 .devflow/ 目录结构，确认安全分级。当用户说「初始化 devflow」「devflow init」「初始化工作流」或在新项目首次使用 DevFlow 时触发。
---

# devflow init — 初始化工作区

**用途：** 在当前项目首次使用 DevFlow，建立 `.devflow/` 目录结构，**自动检测技术栈并生成项目画像**，配置 CodeGraph 与 Meegle，写入 `.gitignore`，确认安全分级。同一项目只需执行一次；`devflow start` 检测到未初始化时会自动触发本命令。

---

## 前置条件

- 必须在项目根目录执行。若当前目录不是根目录（无 README、构建配置文件、包管理文件或源码目录），**且也不是空目录或只有 `.git/`**，则提示用户切换目录后再继续，不得猜测。

---

## 执行步骤

### 1. 根目录校验与项目类型判断

检测以下特征，按三种情况分支处理：

**情况 A：已有项目**（存在任一：README.md、package.json、build.gradle、Cargo.toml、pom.xml、Makefile、Podfile、`*.xcodeproj`、src/ 目录）
→ 继续执行步骤 2（技术栈检测）

**情况 B：全新空项目**（目录为空，或只有 `.git/`，或只有 `.git/` + README.md）
→ 跳转至步骤 2-NEW（新项目引导模式）

**情况 C：无法判断**（有文件但无法识别为上述任何一种）
→ 输出：
```
✗ 当前目录不像项目根目录。
  请切换到项目根目录后重新执行 devflow init。
  如果这是一个全新项目，请确保在项目根目录下执行（空目录或只含 .git 均可）。
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

{根据 workspace.json.reviewSkills 和步骤 2d 的配置结果填写}

| 触发条件 | Skill |
|---------|-------|
| {用户配置的条件 1} | {skill 名} |
| {用户配置的条件 2} | {skill 名} |
| 其余情况 | 通用四维度审查 |

（跳过配置时本节写「全部使用通用四维度审查」）

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

### 2-NEW. 新项目引导模式（情况 B 专用）

目录为空或只有 `.git/` 时，切换为对话式引导，逐步收集技术栈信息，最终产物与步骤 2c 相同（`devflow-profile.md` + `workspace.json.techStack`）。

**第一步：技术栈选择**

```
这是一个全新项目，我来帮你完成初始配置。

请选择项目的主要技术栈（可多选，输入编号，逗号分隔）：

  1.  Android（Kotlin / Java）
  2.  iOS（Swift / Objective-C）
  3.  KMP（Kotlin Multiplatform，Android + iOS 共享代码）
  4.  Flutter
  5.  Vue 3
  6.  React / Next.js
  7.  Node.js 服务端（Express / Koa / NestJS / Fastify）
  8.  Spring Boot / Java 后端
  9.  Go
  10. Python（Django / Flask / FastAPI）
  11. 其他（请说明）
```

**第二步：数据库 / 存储（按检测到的技术栈按需询问）**

```
项目是否使用数据库或存储服务？（可多选，跳过请直接回车）

  1. MySQL / MariaDB
  2. PostgreSQL
  3. MongoDB
  4. Redis
  5. SQLite
  6. Elasticsearch
  7. 对象存储（OSS / S3）
  8. 其他
```

**第三步：项目名称**

```
请输入项目名称（用于生成画像文档，直接回车跳过）：
```

**收集完成后：**

按回答内容生成 `devflow-profile.md` 和 `workspace.json.techStack`，格式与步骤 2c 一致，版本字段填"待配置"（因为还没有实际代码）。

然后询问是否生成项目骨架文件：

```
是否需要生成以下基础文件？（可多选，跳过请直接回车）

  1. .gitignore（按所选技术栈自动生成）
  2. README.md（项目简介骨架）
```

选择后立即生成对应文件，然后继续执行步骤 2d（配置 Review Skill）及后续步骤。

---

#### 2d. 配置 Review Skill（可选）

技术栈画像确认后，对每个检测到的技术栈逐一询问：

```
检测到技术栈：{技术栈名}（如 Android/Kotlin）
请选择 code review 规范来源：

  1. 生成默认规范文件（我来帮你创建，放到项目里，你可以随时修改）
  2. 指定已有 skill 路径（你已经有了自己的规范文件）
  3. 跳过，使用通用四维度审查
```

---

**选择「1. 生成默认规范文件」时：**

在 `{项目根}/.ai/skills/devflow-review-{技术栈标识}/` 下生成 `skill.meta.md`，内容包含该技术栈的通用 checklist，并预留用户自定义区域：

各技术栈的默认模板如下（根据检测到的技术栈选对应模板生成，不生成不相关的）：

---

*Android / KMP Android 端：*

```markdown
<!-- @meta skill_name -->
devflow-review-android
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Android (Kotlin / Java)
<!-- @meta description -->
Android 代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- build.gradle / build.gradle.kts 含 com.android.application / com.android.library / kotlin-android
- 存在 AndroidManifest.xml
- diff 含 *.kt / *.java 且在 Android 模块目录下
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 生命周期与泄漏 | Activity/Fragment 泄漏、监听器未解绑、Handler 匿名内部类 |
| 协程 | viewModelScope/lifecycleScope 作用域、Dispatchers 选择、主线程阻塞 |
| Kotlin 空安全 | `!!` 使用、来自 Java 的平台类型、lateinit 访问前未初始化 |
| Jetpack | LiveData 粘性事件、ViewModel 状态管理、Navigation 使用 |
| View | ViewBinding 泄漏、RecyclerView 复用、notifyDataSetChanged 滥用 |
| 安全 | 敏感数据明文存储、WebView addJavascriptInterface、导出组件校验 |
| 性能 | 主线程 IO、过度绘制、内存抖动 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 price/amount/金额 → 检查 BigDecimal 精度 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*iOS / Swift：*

```markdown
<!-- @meta skill_name -->
devflow-review-ios
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
iOS (Swift / Objective-C)
<!-- @meta description -->
iOS 代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- 存在 *.xcodeproj / *.xcworkspace / Podfile
- diff 含 *.swift / *.m / *.h
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 内存 | 循环引用（[weak self]）、delegate weak 声明、闭包强捕获 |
| 线程安全 | 主线程 UI 操作、DispatchQueue 使用、async/await 上下文 |
| 生命周期 | viewDidLoad/viewWillAppear 职责划分、NotificationCenter 未注销 |
| 安全 | Keychain 存储敏感数据、ATS 配置、硬编码 URL/密钥 |
| 性能 | 主线程 IO、图片内存、UITableView/CollectionView 复用 |
| Swift | 强制解包 `!`、guard/if let 正确性、可选链完整性 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 JSBridge/WKWebView → 检查 JS 注入安全 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Vue / React / 前端 TypeScript：*

```markdown
<!-- @meta skill_name -->
devflow-review-frontend
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Frontend (Vue / React / TypeScript)
<!-- @meta description -->
前端代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- diff 含 *.vue
- diff 含 *.tsx / *.ts 且在 src/ 下
- package.json 含 vue / react 依赖
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 响应式 | Vue：ref/reactive 选择、watch 依赖声明；React：useState 闭包陈旧值、useEffect 依赖数组 |
| 内存 | 事件监听器/定时器未清理、组件卸载后仍操作 DOM |
| 类型安全 | any 使用、类型断言 as、非空断言 ! |
| XSS | v-html / dangerouslySetInnerHTML 使用、用户输入直接插入 DOM |
| 性能 | 组件不必要重渲染、大列表虚拟化、懒加载 |
| 可访问性 | img alt、button aria-label、键盘可操作 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 payment/checkout → 检查 XSS 和输入校验 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Java / Kotlin 后端（Spring Boot / 其他）：*

```markdown
<!-- @meta skill_name -->
devflow-review-backend-java
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Backend (Java / Kotlin / Spring Boot)
<!-- @meta description -->
Java/Kotlin 后端代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- 存在 src/main/java/ 或 src/main/kotlin/
- diff 含 *.java / *.kt 且不在 Android 模块下
- pom.xml 或 build.gradle 含 spring-boot
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 安全 | SQL 注入（拼接字符串 SQL）、权限校验缺失、敏感数据日志打印 |
| 事务 | @Transactional 边界正确性、事务嵌套与回滚 |
| 并发 | 线程安全、锁范围、共享可变状态 |
| 异常 | 异常被吞（空 catch）、统一异常处理缺失 |
| 性能 | N+1 查询、大结果集未分页、全表扫描 |
| 资源 | 连接/流未关闭、try-with-resources 使用 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 amount/price → 检查 BigDecimal 精度 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Go：*

```markdown
<!-- @meta skill_name -->
devflow-review-go
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Go
<!-- @meta description -->
Go 代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件：
- 存在 go.mod
- diff 含 *.go
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 错误处理 | error 未检查、错误被丢弃（_ = err）、panic 使用场景 |
| 并发 | goroutine 泄漏、channel 未关闭、data race、mutex 锁范围 |
| 资源 | defer 关闭文件/连接、context 取消传播 |
| 内存 | 大切片引用导致内存无法回收、map 并发读写 |
| 安全 | SQL 拼接、命令注入、敏感信息日志 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Python：*

```markdown
<!-- @meta skill_name -->
devflow-review-python
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Python
<!-- @meta description -->
Python 代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件：
- 存在 requirements.txt / pyproject.toml / setup.py
- diff 含 *.py
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 安全 | SQL 注入（f-string 拼接）、eval/exec 使用、敏感数据硬编码 |
| 异常 | 裸 except、异常被吞、重要错误未记录 |
| 类型 | 类型注解缺失（函数签名）、Optional 未处理 None |
| 资源 | 文件/连接未用 with 管理、生成器未关闭 |
| 并发 | GIL 理解、asyncio await 遗漏、线程共享状态 |
| 性能 | 列表推导替代 for 循环、不必要的全局变量 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Vue 3：*

```markdown
<!-- @meta skill_name -->
devflow-review-vue
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Vue 3
<!-- @meta description -->
Vue 3 代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- diff 含 *.vue
- package.json 含 "vue" 依赖且版本 >= 3
- 存在 vite.config.ts / vite.config.js 且 package.json 含 vue
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| Composition API | ref/reactive 选择是否合理、computed 是否有副作用、watch/watchEffect 依赖声明完整性 |
| 响应式陷阱 | 解构响应式对象丢失响应性（应用 toRefs）、直接替换整个 reactive 对象、数组索引赋值 |
| 生命周期 | onMounted/onUnmounted 配对（事件监听、定时器、WebSocket）、setup 中异步操作未处理错误 |
| 组件通信 | props 类型声明、emit 事件声明、v-model 双向绑定正确性 |
| 模板安全 | v-html 使用（XSS 风险）、用户输入直接渲染、动态 :href/:src 未过滤 javascript: |
| 性能 | v-for 缺少 :key 或 key 用 index、不必要的 v-if+v-for 同层、大列表未虚拟化、组件未按需懒加载 |
| Pinia / Vuex | store action 异常处理、getter 缓存正确性、跨 store 依赖循环 |
| TypeScript | 组件 props/emits 类型声明、模板 ref 类型标注、any 使用 |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 payment/checkout → 检查 XSS 和输入校验 -->
<!-- 示例：diff 含 *.vue 且含表单元素 → 检查 v-model 校验逻辑 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---

*Node.js 服务端：*

```markdown
<!-- @meta skill_name -->
devflow-review-nodejs
<!-- @meta version -->
1.0.0
<!-- @meta platform_label -->
Node.js (Express / Koa / NestJS / Fastify)
<!-- @meta description -->
Node.js 服务端代码审查规范。由 devflow init 自动生成，可按项目实际情况修改。
<!-- @meta stack_detection -->
命中条件（满足任一即使用本规范）：
- package.json 含 express / koa / fastify / @nestjs/core 依赖
- diff 含 *.ts / *.js 且在 src/ 下，且项目无前端框架特征（无 *.vue / 无 react）
- 存在 tsconfig.json 且 package.json 含 @types/node
<!-- @meta core_checklist -->
## 核心审查清单

| 维度 | 检查项 |
|------|--------|
| 安全 | SQL/NoSQL 注入（字符串拼接查询）、命令注入（exec/spawn 拼接用户输入）、路径穿越（../）、不安全的反序列化 |
| 认证与授权 | 中间件鉴权是否挂载到路由、JWT 验签逻辑、敏感接口缺少权限校验 |
| 输入校验 | 用户输入未校验直接使用、缺少类型校验和长度限制、文件上传类型/大小未限制 |
| 异步错误 | Promise 未 catch、async 函数未 try/catch、Express 异步错误未传给 next(err) |
| 资源泄漏 | 数据库连接/文件句柄未关闭、流未 destroy、定时器未清理 |
| 敏感信息 | 密钥/Token 硬编码在代码中（应读环境变量）、错误响应暴露堆栈信息、日志打印敏感字段 |
| 性能 | 同步 IO（fs.readFileSync 在请求路径上）、大结果集未分页、缺少缓存的高频查询 |
| 依赖安全 | 新增第三方包是否必要、是否有已知漏洞版本（可提示运行 npm audit） |

<!-- 项目专项规则 —— 请在下方添加本项目特有的审查规则 -->
<!-- @meta domain_hit_rules -->
<!-- 示例：diff 含 /api/payment → 检查幂等性和金额精度 -->
<!-- 示例：diff 含 multer/formidable → 检查文件上传安全 -->
<!-- 在此添加本项目的领域命中规则 -->
<!-- @meta end -->
```

---
```
✅ 已生成 Review Skill 文件：
   .ai/skills/devflow-review-{技术栈标识}/skill.meta.md

   这是基于 {技术栈} 的通用审查规范。
   文件底部有「项目专项规则」区域，可按本项目特点添加。
   devflow review 执行时会直接读取此文件。
```

将路径和触发条件写入 `workspace.json.reviewSkills`（触发条件从生成的 `stack_detection` 段提取）。

---

**选择「2. 指定已有 skill 路径」时：**

```
请输入 skill 目录路径（包含 skill.meta.md 的目录）：
> 输入路径

请描述此 skill 的触发条件（当 diff 满足什么特征时使用它）：
示例：「diff 含 *.kt 且存在 AndroidManifest.xml」
      「diff 含 *.vue 或 *.ts」
> 输入触发条件
```

读取该路径下的 `skill.meta.md` 验证文件存在，然后写入 `workspace.json.reviewSkills`。

---

**选择「3. 跳过」时：**

`reviewSkills` 写入 `[]`，`devflow review` 运行时降级为通用四维度审查。

---

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

初始化 `workspace.json`（合并步骤 2 生成的 techStack / codegraph / reviewSkills 配置）：
```json
{
  "currentWorkItem": null,
  "meegle": {
    "projectKey": null,
    "defaultWorkItemType": null
  },
  "techStack": {
    "languages": [],
    "frameworks": [],
    "databases": [],
    "repoStructure": "single",
    "compileCommands": {}
  },
  "reviewSkills": [],
  "codegraph": {
    "strategy": "single-root",
    "roots": [],
    "queryGuide": ""
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

已有项目（情况 A）：

```
✅ DevFlow 初始化完成！

  根目录：{path}
  模式：已有项目（自动检测技术栈）

  ── 技术栈画像 ────────────────────────────────
  语言：{Kotlin + Swift | TypeScript | Java | Go | Python | ...}
  框架：{Android SDK + SwiftUI | Vue 3 | Spring Boot | ...}
  构建：{Gradle 8.x | Maven | Vite + pnpm | CocoaPods | ...}
  数据库：{MySQL + Redis | PostgreSQL | MongoDB | 未检测到}
  基础设施：{Docker + GitHub Actions | K8s | 未检测到}
  测试：{JUnit 5 + XCTest | Jest + Cypress | pytest | 未检测到}
  仓库结构：{单仓库 | Monorepo（apps/web, apps/api） | 壳工程+submodules | iOS+本地Pod}
  完整画像：.devflow/devflow-profile.md

  ── 代码审查 ──────────────────────────────────
  Review Skill：{已配置 n 个专项 skill | 未配置，将使用通用四维度审查}
    {skill名} → {触发条件}

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

全新项目（情况 B）：

```
✅ DevFlow 初始化完成！

  根目录：{path}
  模式：全新项目（对话式配置）

  ── 技术栈画像 ────────────────────────────────
  语言：{用户选择的技术栈}
  数据库：{用户选择的数据库 | 未配置}
  完整画像：.devflow/devflow-profile.md
  （技术栈版本信息待编码后自动补充）

  ── 代码审查 ──────────────────────────────────
  Review Skill：{已配置 n 个专项 skill | 未配置，将使用通用四维度审查}

  ── CodeGraph ─────────────────────────────────
  索引：暂无代码，待第一次 devflow code 完成后执行 codegraph init

  ── 骨架文件 ──────────────────────────────────
  .gitignore：{已生成 | 已跳过}
  README.md：{已生成 | 已跳过}

  ── 配置 ──────────────────────────────────────
  Meegle：{已连接（用户：xxx）| 未配置}
  安全分级：{L0 | L1 | L2}

现在可以使用 `devflow start` 创建第一个需求。
```
