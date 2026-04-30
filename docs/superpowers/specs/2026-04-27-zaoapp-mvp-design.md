# ZaoApp MVP 设计文档

日期：2026-04-27

## 目标

ZaoApp MVP 让用户可以用自然语言描述一个小型效率工具，在 ZaoApp 内生成一个可用的小应用，本地保存，并通过继续对话修改它的外观和数据结构。

第一版重点验证这条闭环：

`描述需求 -> 生成 JSON 配置 -> 预览 -> 保存 -> 使用 -> 修改配置`

生成的小应用可以在 ZaoApp 内真实使用。第一版不导出独立 Flutter 项目、APK 或 IPA。

## 范围

MVP 先支持固定的效率工具类型：

- 待办清单
- 习惯打卡
- 倒计时
- 记账

AI 不生成源码，只返回受控 JSON 配置。Flutter 根据配置渲染小应用，并把小应用配置和运行数据都保存在本机。

MVP 暂不包含：

- 独立 App 导出
- Flutter 源码生成
- 云端同步和账号登录
- 小应用分享或模板市场
- AI 创建任意未知组件
- 复杂自动化规则，例如提醒、奖励、条件流程

## 架构

系统分为三部分。

Flutter 客户端：

- 展示用户的小应用库。
- 提供生成和修改界面。
- 预览和运行生成的小应用。
- 本地保存小应用配置和运行数据。
- 使用 `json_schema` 校验小应用配置，避免无效配置进入渲染器。

后端 API：

- 提供 `/generate`，用于首次生成小应用。
- 提供 `/revise`，用于对话式修改配置。
- 调用 AI 模型。
- 在返回给客户端前校验、修复和标准化 JSON。
- MVP 阶段不保存用户小应用数据。

AI 模型：

- 把用户描述转换成小应用配置 JSON。
- 根据修改指令和旧配置生成新的配置版本。
- 不输出可执行代码。

这样的拆分可以避免客户端暴露 API Key，也可以把 AI 输出限制在可校验的结构化边界内。

## 核心流程

第一屏是小应用库，而不是生成器。这样 ZaoApp 更像一个可以长期使用的工具，用户生成的小应用会沉淀下来并被反复打开。

主流程：

1. 用户打开 ZaoApp，看到“我的小应用”。
2. 用户点击创建。
3. 用户描述想要的小应用。
4. Flutter 把描述发送到后端 `/generate`。
5. 后端返回通过校验的小应用配置。
6. Flutter 用渲染器展示小应用预览。
7. 用户保存，或继续提出修改。
8. 保存后的小应用出现在应用库。
9. 用户打开已保存的小应用，并在 ZaoApp 内使用。

修改流程：

1. 用户在预览页或已保存的小应用中提出修改。
2. 例如：“加一个优先级字段”或“改成蓝色”。
3. Flutter 把旧配置和修改指令发送到后端 `/revise`。
4. 后端返回通过校验的新配置版本。
5. Flutter 展示新版本预览。
6. 用户确认后保存更新。

## 模块

Application Library，小应用库：

- 展示已保存的小应用。
- 在渲染器中打开小应用。
- 支持重命名、删除和复制。
- 展示最近使用的小应用。

Generation Session，生成会话：

- 记录用户的初始描述。
- 记录加载、成功和失败状态。
- 保存当前预览配置。
- 保存修改消息和配置版本。

Mini App Renderer，小应用渲染器：

- 根据 JSON 配置渲染支持的小应用类型。
- 提供固定、已知的组件，例如列表、表单、计数器、勾选状态和简单统计。
- 遇到不支持的配置时拒绝渲染，而不是尝试解释未知结构。
- 渲染前通过 `json_schema` 校验配置结构。

Local Storage，本地存储：

- 保存小应用配置。
- 保存每个小应用的运行记录。
- 保存最近打开时间、当前版本等元数据。

Backend Config Service，后端配置服务：

- 构造生成和修改所需的提示词。
- 调用 AI 模型。
- 使用服务端 Schema 校验输出。
- 返回标准化配置或结构化错误。

## Flutter 客户端架构

Flutter 端采用 Feature-first + 简单分层架构。MVP 不使用完整 Clean Architecture，也不把所有逻辑堆在 `main.dart`。代码按业务功能组织，每个功能模块内部保留 UI、状态和数据入口，公共能力放到 `core` 和 `shared`。

UI 组件库使用 Forui。Forui 只作为表现层组件库，用于应用库、生成器、预览页、运行器外壳、表单、弹窗、Toast 和导航等界面，不改变 Feature-first 架构、配置 Schema、Renderer 白名单和状态管理方案。

UI 质量控制使用 `ui-ux-pro-max`。它不替代 Forui，而是作为设计系统、可访问性、响应式、交互反馈和交付验收的质量门禁。ZaoApp 的产品内界面优先采用 Flat Design Mobile / Touch-first 方向，避免复杂装饰、营销页式 hero、过度动效和不可控视觉风格。

应用内页面路由使用 `go_router`。MVP 只使用它管理基础页面导航，路由配置集中放在 `lib/app/app_router.dart`，暂不启用平台级 deep link、复杂 redirect/auth guard 或 `go_router_builder`。这样可以先保留清晰的页面边界和可测试路由入口，又不提前引入账号、权限和跨平台链接配置的复杂度。

推荐目录结构：

```text
lib/
  main.dart
  app/
    zao_app.dart
    app_router.dart
    app_theme.dart

  core/
    config/
      mini_app_schema.dart
      mini_app_validator.dart
    errors/
      app_error.dart
      result.dart
    storage/
      local_storage.dart
    utils/
      id_generator.dart

  shared/
    widgets/
    models/

  features/
    library/
      app_library_page.dart
      app_library_controller.dart
      app_library_repository.dart

    generator/
      generator_page.dart
      generation_session_controller.dart
      config_generation_service.dart
      mock_config_generation_service.dart

    renderer/
      mini_app_runner_page.dart
      mini_app_renderer.dart
      renderer_registry.dart
      renderers/
        todo_renderer.dart
        habit_renderer.dart
        countdown_renderer.dart
        expense_renderer.dart

    runtime_data/
      runtime_data_repository.dart
      runtime_data_models.dart
```

核心边界：

- `generator` 负责“描述 -> 配置”。第一阶段使用 `MockConfigGenerationService`，后续替换为真实后端服务时，页面和控制器不需要大改。
- `renderer` 负责“配置 -> UI”。它不关心配置来自 AI、mock 响应还是本地存储。入口是 `MiniAppConfig`，渲染前统一通过 `json_schema` 校验。
- `library` 负责“我的小应用”。它管理保存、打开、重命名、删除和复制，不参与具体小应用的运行逻辑。
- `runtime_data` 负责“小应用使用过程中产生的数据”。例如待办项、打卡记录、记账记录，不和配置 JSON 混在一起。
- `core/config` 放配置 Schema 和校验器，避免各功能模块重复写校验逻辑。
- `core/storage` 提供本地存储抽象，具体存储方案确定前先通过接口隔离。
- `shared/widgets` 可以封装 Forui 基础组件的项目级用法，避免业务模块直接散落主题、间距和交互细节。

MVP 阶段状态管理使用 Flutter 原生 `ChangeNotifier` 或 `ValueNotifier` 做页面级 controller：

- `AppLibraryController`
- `GenerationSessionController`
- `MiniAppRunnerController`

暂不引入 Riverpod、BLoC 或 Redux。当前核心风险在配置模型、校验和渲染器，而不是复杂状态同步。等后续加入账号、云同步、多设备状态或更复杂的跨页面共享状态时，再评估是否引入专门状态管理库。

Flutter 端主数据流：

```text
用户输入描述
 -> GenerationSessionController
 -> ConfigGenerationService
 -> MockConfigGenerationService
 -> MiniAppConfig
 -> MiniAppValidator(json_schema)
 -> MiniAppRenderer
 -> 用户预览
 -> AppLibraryRepository 保存
 -> AppLibraryPage 展示
```

## UI 质量门禁

凡是涉及页面、组件、交互、布局、视觉样式、可访问性或响应式的改动，都必须经过 UI 质量门禁。

实施前：

- 使用 `ui-ux-pro-max` 检索设计系统、UX 规则或 Flutter stack 指南。
- 确认当前任务适用的视觉方向、布局方式、触控要求和可访问性要求。
- 将 UI 质量要求写入实施计划，而不是在最后临时“美化”。

实现中：

- 使用 Forui 和 `shared/widgets` 组合页面，不在业务页面散落临时样式。
- 每个核心页面都必须覆盖 loading、empty、success、error、retry 状态。
- 表单必须有可见 label、必要 helper text 和就近 error message。
- 可点击目标必须满足移动端触控尺寸要求，至少 44pt / 48dp。
- 不使用 emoji 作为结构性图标。
- 使用 `LayoutBuilder` 或约束驱动布局，避免固定宽度造成小屏溢出。
- Renderer 只能使用白名单抽象组件，不能让 JSON 直接指定 Forui 组件类名。

验收时：

- 检查小屏手机、常规手机、平板和横屏场景。
- 检查文本是否溢出、按钮是否被挤压、列表是否可滚动、表单是否被键盘遮挡。
- 检查深浅色模式下的文本、边框、错误和禁用状态是否可读。
- 检查无效配置、空应用库、生成失败、本地存储失败等异常 UI。
- 运行 `flutter analyze`、`flutter test` 和 `git diff --check`。

## 数据模型

小应用配置和运行数据必须分开。

小应用配置由 AI 生成和修改，用来描述小应用的结构和外观：

```json
{
  "id": "habit_001",
  "schemaVersion": 1,
  "appVersion": 1,
  "name": "每日习惯打卡",
  "type": "habit_tracker",
  "theme": {
    "color": "blue",
    "icon": "check_circle"
  },
  "fields": [
    {
      "key": "title",
      "label": "习惯名称",
      "type": "text"
    },
    {
      "key": "frequency",
      "label": "频率",
      "type": "select",
      "options": ["每天", "每周"]
    }
  ]
}
```

运行数据由用户使用小应用时产生，并保存在本机：

- 待办事项
- 习惯完成日期
- 记账记录
- 倒计时状态
- 最近打开时间

MVP 阶段，后端不接收运行记录。修改请求只发送小应用配置和用户的修改指令。

## MVP 技术细化决策

本地存储：

- MVP 先使用 JSON 文件作为本地存储格式，通过 `core/storage/local_storage.dart` 统一封装读写。
- 小应用配置和运行数据分别保存，避免修改配置时误伤用户数据。
- 配置数据保存为 `mini_apps.json`，运行数据按 `appId` 拆分保存，例如 `runtime_<appId>.json`。
- 后续如果运行数据增长明显，再迁移到 Drift、Isar 或 SQLite；迁移不影响上层 repository 接口。

配置版本：

- 每份小应用配置必须包含 `schemaVersion` 和 `appVersion`。
- `schemaVersion` 表示配置结构版本，用于兼容旧配置。
- `appVersion` 表示某个小应用自身的修改版本，每次用户接受修改后递增。
- MVP 只支持 `schemaVersion: 1`，遇到更高版本时展示“不支持的配置版本”错误。

配置示例：

```json
{
  "id": "habit_001",
  "schemaVersion": 1,
  "appVersion": 1,
  "name": "每日习惯打卡",
  "type": "habit_tracker"
}
```

Renderer 白名单组件：

- 文本展示
- 单行文本输入
- 多行文本输入
- 数字输入
- 日期输入
- 下拉选择
- 开关
- 按钮
- 列表
- 勾选项
- 统计摘要
- 空状态
- 错误状态

JSON 配置只能选择这些抽象组件和固定小应用类型，不能直接指定 Forui 具体组件类名。Forui 只在 Flutter 渲染层内部作为实现细节使用。

Mock 后端响应：

第一阶段用 mock 服务模拟真实后端接口形态，避免 UI 绑定临时结构。

`generate` 成功响应：

```json
{
  "ok": true,
  "config": {
    "id": "todo_001",
    "schemaVersion": 1,
    "appVersion": 1,
    "name": "每日待办",
    "type": "todo_list"
  }
}
```

`revise` 成功响应：

```json
{
  "ok": true,
  "config": {
    "id": "todo_001",
    "schemaVersion": 1,
    "appVersion": 2,
    "name": "每日待办",
    "type": "todo_list"
  }
}
```

失败响应：

```json
{
  "ok": false,
  "error": {
    "code": "unsupported_app_type",
    "message": "当前只支持待办、习惯打卡、倒计时和记账。"
  }
}
```

错误码：

- `invalid_prompt`：用户描述为空、过短或无法理解。
- `unsupported_app_type`：用户想生成的类型不在 MVP 支持范围内。
- `invalid_config`：AI 或 mock 返回的配置无法通过 Schema 校验。
- `unsupported_revision`：用户要求修改复杂逻辑、提醒、条件规则或未知组件。
- `unsupported_schema_version`：配置版本高于当前客户端支持范围。
- `storage_failure`：本地配置或运行数据保存失败。
- `service_unavailable`：后端或 mock 服务不可用。

Flutter 路由：

- 使用 `go_router` 管理应用内页面路由。
- 路由配置集中在 `lib/app/app_router.dart`，应用入口使用 `MaterialApp.router`。
- MVP 规划路由为 `/`、`/generate`、`/preview`、`/apps/:appId` 和 `/apps/:appId/revise`。
- 第一阶段先接入 `/` 根路由，指向小应用库或临时 smoke 页面；其他页面实现时再逐步补充对应路由。
- 暂不启用平台级 deep link、复杂 redirect/auth guard 或 `go_router_builder`。

## 支持的修改

MVP 支持修改：

- 标题
- 图标
- 主题色
- 字段名称
- 字段新增和删除
- 当前小应用类型支持的简单视图默认值，例如排序或分组

MVP 不支持：

- 任意业务逻辑
- 定时提醒
- 条件规则
- 代码执行
- 渲染器已知组件之外的新组件类型

## 错误处理

后端必须把 AI 输出当成不可信草稿：

1. 解析 JSON。
2. JSON 格式错误时尝试修复一次。
3. 使用小应用配置 Schema 校验。
4. 补齐和标准化默认值。
5. 返回配置或结构化错误。

后端错误处理：

- JSON 无效：尝试修复一次，仍失败则返回错误。
- Schema 不通过：返回生成失败，并提示用户重试或换一种描述。
- 类型不支持：告诉客户端当前支持的类型。
- 修改不支持：返回清晰的限制说明。

Flutter 错误处理：

- 后端不可用：保留用户输入，并允许重试。
- 配置无效：展示不会崩溃的错误页。
- 本地存储失败：提供重试或重置当前小应用的入口。
- 配置缺少部分默认值：只有 Schema 明确允许时，渲染器才使用默认值补齐。
- 配置版本不支持：展示“不支持的配置版本”，不尝试降级渲染。

## 测试策略

第一层测试聚焦核心闭环。

Flutter 测试中使用 `mocktail` 隔离外部依赖，优先 mock 后端配置服务、本地存储接口和生成会话状态，避免 widget 测试直接依赖真实网络或真实持久化。

生成测试：

- 输入“做一个每日习惯打卡应用”，可以得到合法配置。
- 不支持的描述会明确失败。

渲染测试：

- 每个支持的小应用类型都能从一份合法配置渲染出来。
- 无效或不支持的配置不会导致 App 崩溃。
- `MiniAppRenderer` 会根据 `type` 分发到正确的具体渲染器。
- `MiniAppValidator` 会拒绝不符合 Schema 的配置。

存储测试：

- 保存后的小应用配置会出现在应用库。
- 重新打开后，运行数据仍然存在。
- `AppLibraryRepository` 和 `RuntimeDataRepository` 可以通过 `mocktail` 隔离测试页面 controller。

修改测试：

- “加一个优先级字段”这类请求会生成新的配置版本。
- 新增兼容字段时，已有运行数据不丢失。
- 不支持的逻辑修改会明确失败。

## 里程碑

M1：本地渲染器

- 定义小应用配置 Schema。
- 创建本地示例 JSON 配置。
- 使用 `json_schema` 校验示例配置。
- 从本地配置渲染待办、习惯打卡、倒计时和记账。
- 提供 mock 后端响应，让生成入口可以先拿到稳定的配置数据。

M2：应用库和本地持久化

- 本地保存生成的小应用配置。
- 展示已保存的小应用列表。
- 支持打开、重命名、删除和复制小应用。
- 按小应用保存运行数据。
- 生成和修改流程继续使用 mock 后端响应，先验证客户端完整闭环。

M3：后端生成 API

- 添加 `/generate`。
- 从后端调用 AI 模型。
- 校验并标准化 AI 输出。
- 将 Flutter 生成界面连接到后端。

M4：对话式修改

- 添加 `/revise`。
- 发送当前配置和用户修改指令。
- 预览新的配置版本。
- 保存用户接受的修改。

M5：可靠性和体验打磨

- 增加加载、重试和空状态。
- 增加 Schema 失败处理。
- 为生成、渲染、存储和修改添加聚焦测试。

## 实施前待决策项

- 后端语言和框架。
- 后端 Schema 校验库。如果后端不使用 Dart，需要选择对应语言的 JSON Schema 校验库。
- AI 服务商和模型。

推荐实施顺序：先使用 mock 后端响应完成 M1 和 M2，验证 Flutter 端生成、预览、保存、运行和修改闭环，再接入后端和真实 AI 调用。

已确认的实施决策：

- Flutter 客户端 Schema 校验库使用 `json_schema: ^5.2.2`。
- Flutter 测试 mock 库使用 `mocktail: ^1.0.5`，并放在 `dev_dependencies`。
- 第一阶段先使用 mock 后端响应，不直接接入真实 AI 后端。
- Flutter 客户端采用 Feature-first + 简单分层架构。
- MVP 阶段状态管理先使用 `ChangeNotifier` 或 `ValueNotifier`，暂不引入额外状态管理库。
- Flutter UI 组件库使用 Forui。Forui 只用于表现层，不允许 JSON 配置直接指定任意 Forui 组件。
- MVP 本地存储先使用 JSON 文件，并通过 repository 和 storage 抽象隔离，后续可迁移到数据库。
- 小应用配置必须包含 `schemaVersion` 和 `appVersion`，MVP 只支持 `schemaVersion: 1`。
- UI 质量控制使用 `ui-ux-pro-max`，并作为所有页面、组件、交互和响应式改动的质量门禁。
- Flutter 客户端应用内页面路由使用 `go_router`。MVP 阶段只做基础页面导航，暂不启用平台级 deep link、复杂 redirect/auth guard 或 `go_router_builder`。
