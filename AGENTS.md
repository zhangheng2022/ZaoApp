# AGENTS.md

## 交流语言

- 优先使用中文和用户沟通。
- 技术名词、包名、文件名、命令和代码标识保留英文。
- 说明问题时直接给出结论、原因和下一步，避免空泛表述。

## 项目定位

ZaoApp 是一个 AI 小应用生成平台。MVP 阶段的核心闭环是：

`描述需求 -> 生成 JSON 配置 -> 预览 -> 保存 -> 使用 -> 修改配置`

第一版生成的小应用运行在 ZaoApp 内部，不导出独立 Flutter 项目、APK 或 IPA。

## 设计文档

- 主要设计文档在 `docs/superpowers/specs/2026-04-27-zaoapp-mvp-design.md`。
- 开始任何较大改动前，先阅读该设计文档，并保持实现与其中的架构决策一致。
- 如果实现需要改变设计决策，先更新设计文档，再改代码。

## Flutter 架构约定

- Flutter 客户端采用 Feature-first + 简单分层架构。
- 代码按业务模块组织，公共能力放到 `core` 和 `shared`。
- 推荐目录结构：

```text
lib/
  app/
  core/
    config/
    errors/
    storage/
    utils/
  shared/
    widgets/
    models/
  features/
    library/
    generator/
    renderer/
    runtime_data/
```

模块边界：

- `features/generator` 负责“描述 -> 配置”。
- `features/renderer` 负责“配置 -> UI”。
- `features/library` 负责“我的小应用”列表、打开、保存、重命名、删除和复制。
- `features/runtime_data` 负责小应用运行数据。
- `core/config` 负责配置 Schema 和校验。
- `core/storage` 负责本地存储抽象。
- 应用内页面路由使用 `go_router`，路由配置集中放在 `lib/app/app_router.dart`。
- MVP 阶段只使用 `go_router` 管理基础页面导航，暂不启用平台级 deep link、复杂 redirect/auth guard 或 `go_router_builder`。

## UI 约定

- UI 组件库使用 Forui。
- Forui 只作为表现层组件库，不改变架构边界。
- JSON 配置不能直接指定任意 Forui 组件。
- `shared/widgets` 可封装 Forui 的项目级用法，避免业务模块散落主题、间距和交互细节。

## UI Quality Gate

- 涉及页面、组件、交互、布局、视觉样式、可访问性或响应式的改动，必须使用 `ui-ux-pro-max`。
- ZaoApp 的产品内界面优先采用 Flat Design Mobile / Touch-first 方向，避免复杂装饰、营销页式 hero、过度动效和不可控视觉风格。
- 开始 UI 实现前，先根据任务运行 `ui-ux-pro-max` 的设计系统、UX 或 Flutter stack 检索，并把结论落实到实现计划。
- Forui 是组件实现层，`ui-ux-pro-max` 是质量判断和验收层，二者不互相替代。
- 每个核心页面必须覆盖 loading、empty、success、error、retry 状态。
- 所有可点击目标应满足移动端触控尺寸要求，至少 44pt / 48dp。
- 表单必须有可见 label、必要 helper text、就近 error message，不使用 placeholder 代替 label。
- Icon 不使用 emoji 作为结构性图标，优先使用 Forui 或项目统一图标体系。
- 页面应使用 `LayoutBuilder` 或约束驱动布局，避免固定宽度导致小屏溢出。
- 交付 UI 前至少检查小屏手机、常规手机、平板和横屏场景。
- UI 交付前必须验证 `flutter analyze`、`flutter test` 和 `git diff --check`。

## 状态管理

- MVP 阶段优先使用 Flutter 原生 `ChangeNotifier` 或 `ValueNotifier`。
- 暂不引入 Riverpod、BLoC、Redux 等额外状态管理库。
- 只有在账号、云同步、多设备状态或复杂跨页面共享状态出现后，才重新评估状态管理方案。

## 配置与数据

- AI 或 mock 服务只返回受控 JSON 配置，不生成源码。
- 小应用配置和运行数据必须分开保存。
- 每份小应用配置必须包含 `schemaVersion` 和 `appVersion`。
- MVP 只支持 `schemaVersion: 1`。
- 渲染前必须使用 `json_schema` 校验配置。
- Renderer 只能渲染白名单组件和固定小应用类型。

## Mock 后端

- 第一阶段先使用 mock 后端响应，不直接接入真实 AI 后端。
- `ConfigGenerationService` 应该通过接口隔离，先由 `MockConfigGenerationService` 实现。
- 后续接入真实后端时，不应要求页面和 controller 大规模重写。

## 本地存储

- MVP 本地存储先使用 JSON 文件。
- 通过 repository 和 storage 抽象隔离具体存储实现。
- 配置数据和运行数据分开保存。
- 后续可以迁移到 Drift、Isar 或 SQLite，但不应影响上层模块接口。

## 测试要求

- 运行静态分析：`flutter analyze`
- 运行测试：`flutter test`
- 提交前检查空白问题：`git diff --check`
- Flutter 测试 mock 库使用 `mocktail`。
- 优先测试：
  - 配置 Schema 校验
  - mock 生成服务
  - renderer 类型分发
  - 应用库保存和打开
  - 运行数据与配置数据分离

## 依赖约定

- `json_schema` 用于 Flutter 客户端配置校验。
- `mocktail` 放在 `dev_dependencies`。
- Forui 用于 UI 表现层。
- `go_router` 用于 Flutter 客户端应用内页面路由。
- 新增依赖前先确认是否真的需要，并同步更新设计文档中的实施决策。

## Git 与文件修改

- 不要回滚用户已有改动，除非用户明确要求。
- 不要提交无关格式化、无关重构或 IDE 元数据。
- 修改文件前先确认当前 `git status --short`。
- 如果只改文档，不要顺手改业务代码。
- 如果只改业务代码，不要顺手重排设计文档。

## Superpowers 工作流

- 用户明确要求使用 Superpowers 时，优先遵循 Superpowers 相关流程。
- 新功能或行为变更先做设计确认，再进入实施计划。
- 遇到测试失败或异常行为时，先定位根因，再修复。
- 声称完成前必须用实际命令验证。
