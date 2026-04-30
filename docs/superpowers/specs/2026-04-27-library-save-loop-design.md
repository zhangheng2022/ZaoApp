# Library Save Loop Design

日期：2026-04-27

## 目标

本阶段实现 ZaoApp MVP 的最小保存闭环：

`生成预览 -> 保存配置 -> 回到应用库 -> 应用库展示已保存小应用`

这一步承接已完成的 mock 生成和 renderer 预览能力，把生成出来的受控 JSON 配置落到本地 JSON 文件，并让首页从本地数据渲染列表。目标是让用户看到“保存后会沉淀到我的小应用”，但不扩展到完整运行数据和修改流程。

## 范围

本阶段包含：

- 定义小应用库 repository 接口。
- 使用 JSON 文件保存小应用配置。
- 应用库首页支持 loading、empty、success、error、retry 状态。
- 生成页在预览成功后提供保存入口。
- 保存成功后回到应用库，并展示刚保存的小应用。

本阶段不包含：

- 运行数据保存。
- 打开已保存小应用的完整 runner 页面。
- 重命名、删除、复制。
- 对话式 revision。
- 真实 AI 后端。
- 云同步和账号。

## 架构

新增 `core/storage` 和补全 `features/library`。

推荐文件：

```text
lib/core/storage/
  local_json_storage.dart

lib/features/library/
  app_library_controller.dart
  app_library_repository.dart
  app_library_page.dart
```

职责：

- `LocalJsonStorage`：负责在本地读写 JSON 文件，不理解业务含义。
- `AppLibraryRepository`：负责保存、读取小应用配置，并在保存前使用 `MiniAppValidator` 校验配置。
- `FileAppLibraryRepository`：基于 `LocalJsonStorage` 操作 `mini_apps.json`。
- `AppLibraryController`：页面级 `ChangeNotifier`，管理加载、错误、重试和已保存列表。
- `AppLibraryPage`：只根据 controller 状态渲染 UI。
- `GeneratorPage`：预览成功后显示保存按钮，通过 repository 保存当前 `previewConfig`。

`Application` 或 `app_router.dart` 负责创建并注入同一个 repository 实例，保证生成页保存的数据能被首页读取。

## 数据格式

`mini_apps.json` 保存配置列表。MVP 阶段先保存原始配置 Map，外加最小元数据：

```json
[
  {
    "config": {
      "id": "todo_mock",
      "schemaVersion": 1,
      "appVersion": 1,
      "name": "待办清单",
      "type": "todo_list"
    },
    "savedAt": "2026-04-27T20:00:00.000Z",
    "updatedAt": "2026-04-27T20:00:00.000Z"
  }
]
```

规则：

- 配置和运行数据保持分离；本文件只保存配置。
- 保存前必须通过 `MiniAppValidator`。
- `schemaVersion` 只接受 `1`。
- 如果保存相同 `id`，覆盖该配置并更新 `updatedAt`，不新增重复项。
- 读取时如果文件不存在，返回空列表。
- 读取时如果 JSON 损坏或结构不符合预期，进入错误状态，不静默清空用户数据。

## 页面行为

### 应用库首页

状态：

- `loading`：启动时读取 `mini_apps.json`。
- `empty`：没有保存的小应用，显示创建入口。
- `success`：展示已保存小应用列表。
- `error`：展示读取失败原因和重试按钮。

列表项展示：

- 小应用名称。
- 类型标签，例如 `todo_list`。
- 最近更新时间。

点击列表项暂时不进入完整 runner。若需要可先展示“打开已保存小应用”占位页，但本阶段不把 runner 纳入范围。

### 生成页

预览成功后：

- 显示 `保存到我的小应用` 按钮。
- 保存期间按钮禁用并显示保存中状态。
- 保存成功后导航到 `/`。
- 保存失败时显示错误和重试路径，不清空当前预览。

## UI 质量要求

继续遵循 Flat Design Mobile / Touch-first：

- 使用 Forui 表现层组件。
- 表单保留可见 label 和 helper text。
- 保存按钮使用 `FButton(size: .lg)`，满足 48dp 触控目标。
- 应用库页面继续使用 `LayoutBuilder` 和宽度约束，避免小屏溢出。
- 应用库和生成页都覆盖 loading、empty、success、error、retry。
- 不使用 emoji 作为结构性图标。

## 错误处理

错误来源：

- 本地 JSON 文件读写失败。
- 文件内容不是列表。
- 列表项缺少 `config`。
- 配置未通过 `MiniAppValidator`。

处理规则：

- 读取失败时应用库进入 error，并提供 retry。
- 保存失败时生成页保留 preview，并展示保存错误。
- 保存非法配置时不写入文件，并返回明确错误。
- 不在 UI 层直接吞掉 repository 异常。

## 测试策略

新增单元测试：

- repository 读取不存在文件返回空列表。
- repository 保存合法配置后可读取。
- repository 保存相同 `id` 时覆盖而不是重复。
- repository 拒绝非法 schema 或不支持 type。
- storage 读到损坏 JSON 时返回错误。

新增 controller 测试：

- 应用库 controller 初始加载 empty。
- 加载成功后进入 success 并持有列表。
- 加载失败后进入 error，retry 可重新加载。

新增 widget 测试：

- 首页 empty 状态显示创建入口。
- 首页 success 状态显示保存的小应用名称和类型。
- 首页 error 状态显示重试入口。
- 生成成功后显示保存按钮。
- 点击保存后调用 repository 并回到首页。
- 保存失败时保留预览并显示错误。

继续运行：

```powershell
flutter analyze
flutter test
git diff --check
```

## 后续阶段

本阶段完成后，下一步再做：

`应用库列表 -> 打开已保存小应用 -> 在 runner 中使用 -> 运行数据单独保存`

届时新增 `features/renderer/mini_app_runner_page.dart` 和 `features/runtime_data`，不把运行数据混入 `mini_apps.json`。
