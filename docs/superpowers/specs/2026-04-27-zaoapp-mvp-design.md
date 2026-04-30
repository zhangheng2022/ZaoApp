# ZaoApp MVP 设计文档

日期：2026-04-27

## 目标

ZaoApp MVP 的核心闭环是：

`描述需求 -> 生成 GenUI surface -> 预览 -> 保存 -> 使用 -> 修改`

第一版生成的小应用运行在 ZaoApp 内部，不导出独立 Flutter 项目、APK 或 IPA。ZaoApp 不执行任意 JS/Dart 代码，也不使用 WebView 承载小应用。

## 关键决策：GenUI-only runtime

ZaoApp 小应用运行时只使用 Flutter GenUI：

- 不再维护 `todo_list`、`habit_tracker`、`countdown`、`expense_tracker` 这类内置 renderer 分发。
- 不再保存 `type: todo_list` 这类固定应用类型。
- AI 生成的是 GenUI/A2UI surface，ZaoApp 保存并重新运行这个 surface。
- GenUI 仍是 alpha/experimental，因此所有 GenUI 相关 API 封装在 `features/genui_runtime` 内，避免污染应用库、生成器、存储和路由边界。
- GenUI 运行失败时显示错误和重试 UI，不回退到旧内置 renderer。

## 数据模型

小应用保存为 `GenUiMiniAppPackage`：

```json
{
  "id": "genui_001",
  "schemaVersion": 1,
  "appVersion": 1,
  "name": "每日待办",
  "prompt": "帮我做一个每日待办清单",
  "surfaceJson": [
    {
      "surfaceUpdate": {
        "surfaceId": "surface_main",
        "components": []
      }
    },
    {
      "beginRendering": {
        "surfaceId": "surface_main",
        "root": "root"
      }
    }
  ],
  "runtimeData": {},
  "savedAt": "2026-04-30T00:00:00.000Z",
  "updatedAt": "2026-04-30T00:00:00.000Z"
}
```

约束：

- `schemaVersion` MVP 只支持 `1`。
- `surfaceJson` 必须是可被 GenUI `A2uiMessage.fromJson` 解析的 A2UI message 列表。
- `surfaceJson` 必须包含至少一个 `beginRendering`，用于确定运行 surface。
- `runtimeData` 是 key-value JSON，不按固定小应用类型建模。

## 模块边界

推荐目录结构：

```text
lib/
  app/
    app_router.dart
    firebase_bootstrap.dart
  features/
    generator/
      genui_generation_service.dart
      mock_genui_generation_service.dart
      generation_session_controller.dart
      generator_page.dart
    genui_runtime/
      genui_mini_app_package.dart
      genui_package_validator.dart
      genui_surface_runner.dart
      runtime_bridge_handler.dart
      genui_mini_app_runner_page.dart
    library/
      app_library_page.dart
      genui_mini_app_repository.dart
```

职责：

- `generator` 负责“prompt -> GenUiMiniAppPackage”。
- `genui_runtime` 负责 package 校验、A2UI message 回放、`GenUiSurface` 渲染和受控 runtime bridge。
- `library` 负责保存、读取、展示和打开 package。
- `app` 负责路由和 Firebase 初始化。

## 生成策略

第一版提供两条生成路径：

- `MockGenUiGenerationService`：用于本地开发和自动化测试，返回确定性的 GenUI surface。
- `FirebaseGenUiGenerationService`：使用 Firebase AI Logic + `genui_firebase_ai` 调用 Gemini 生成 A2UI surface。

当前仓库没有 Firebase 平台配置文件，因此默认路由使用 mock 服务。补齐 `firebase_options.dart`、Android/iOS/macOS 等平台配置后，可以把注入的生成服务切换到 `FirebaseGenUiGenerationService`。

## Runtime bridge

GenUI 只能通过受控 bridge 修改运行数据或触发宿主能力。第一版白名单：

- `runtime.get`
- `runtime.set`
- `runtime.patch`
- `toast.show`

不开放任意文件、网络、系统权限或代码执行能力。

## 本地存储

MVP 使用 JSON 文件保存小应用包：

- 文件名：`mini_apps.json`
- 内容：`GenUiMiniAppPackage` 列表
- 同 id 保存时覆盖旧 package

后续可迁移到 Drift、Isar 或 SQLite，但不应影响 `GenUiMiniAppRepository` 接口。

## UI 与测试要求

产品内界面保持 Flat Design Mobile / Touch-first：

- 首页显示 loading、empty、error、success 状态。
- 生成页显示输入、loading、preview、error、retry、save 状态。
- 表单必须有可见 label 和 helper text。
- 触控目标保持移动端可点击尺寸。
- 运行器错误时显示可理解错误和重试入口。

提交前验证：

- `flutter analyze`
- `flutter test`
- `git diff --check`
