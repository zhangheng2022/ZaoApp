# Generator Mock Preview Design

日期：2026-04-27

## 目标

本阶段实现 ZaoApp MVP 主链路的前半段：

`输入自然语言描述 -> mock 生成 JSON 配置 -> 客户端校验 -> renderer 预览`

本阶段不实现保存、小应用库持久化、运行数据或真实 AI 后端接入。保存和本地 JSON 文件存储作为后续 `library + storage` 阶段单独规划。

## 已确认取舍

- 页面形态采用单页上下流：输入区在上，预览区在下。
- `MockConfigGenerationService` 根据关键词映射到 4 种 MVP 类型，无法识别时回退 `todo_list`。
- 正常 mock 服务不通过用户输入魔法词触发失败；错误和重试状态通过测试注入失败 service 覆盖。
- 本阶段只做到预览，不包含保存按钮或应用库展示。

## 架构

新增 `features/generator` 模块，遵循现有 Feature-first + 简单分层架构。

拟新增文件：

```text
lib/features/generator/
  config_generation_service.dart
  mock_config_generation_service.dart
  generation_session_controller.dart
  generator_page.dart
```

职责划分：

- `ConfigGenerationService`：定义生成接口，隔离 mock 和未来真实后端。
- `MockConfigGenerationService`：根据描述返回受控 `Map<String, Object?>` 配置。
- `GenerationSessionController`：管理页面级状态，调用 service，使用 `MiniAppValidator` 校验配置。
- `GeneratorPage`：只负责表单输入、按钮交互和不同状态的 UI 展示。

`app_router.dart` 新增 `/generate` 路由。现有 `/` 仍保留当前 smoke library 占位，不在本阶段重做应用库。

## 状态模型

`GenerationSessionController` 管理以下状态：

- `idle`：用户尚未请求生成。
- `loading`：正在生成配置。
- `success`：生成并校验成功，持有 `previewConfig`。
- `error`：生成失败、空输入或配置校验失败，持有错误消息。

controller 还保存最近一次成功或失败请求的描述，用于 retry。

空输入由 controller 拒绝并进入 `error`，错误消息应靠近表单或预览状态区域显示，不能静默失败。

## Mock 生成规则

`MockConfigGenerationService.generate(String description)` 返回 schemaVersion 1 配置。

关键词映射：

- 待办、todo、task -> `todo_list`
- 习惯、打卡、habit -> `habit_tracker`
- 倒计时、countdown、deadline -> `countdown`
- 记账、expense、money -> `expense_tracker`
- 未识别 -> `todo_list`

每个返回配置必须包含：

- `id`
- `schemaVersion: 1`
- `appVersion: 1`
- `name`
- `type`
- 可选 `fields`

service 不负责 UI 状态，也不绕过 `MiniAppValidator`。controller 必须在进入 preview 前统一校验。

## UI 设计

页面采用 Flat Design Mobile / Touch-first 方向，避免营销页式 hero、复杂装饰和不可控视觉风格。

页面结构：

- 标题：创建小应用。
- 表单区：
  - 可见 label：描述你想要的小应用。
  - helper text：提示用户描述一个待办、习惯、倒计时或记账工具。
  - 多行输入框。
  - 主按钮：生成预览。
- 预览区：
  - `idle`：显示空状态，引导输入描述。
  - `loading`：显示生成中反馈，按钮禁用。
  - `success`：显示 `MiniAppRenderer(config: previewConfig)`。
  - `error`：显示错误原因和重试按钮。

布局要求：

- 使用 Forui 作为表现层组件库。
- 使用 `Form` 和 submit validation，不做 placeholder-only input。
- 使用 `LayoutBuilder` 或约束驱动布局，避免固定宽度导致小屏溢出。
- 点击目标至少满足 44pt / 48dp，主要按钮高度不低于 48dp。
- 相邻可点击目标间距至少 8dp。
- 不使用 emoji 作为结构性图标。
- 加载、错误、空状态和重试状态必须有明确视觉反馈。

## UI/UX Pro Max 结论

项目内存在 `.agents/skills/ui-ux-pro-max`。本阶段使用其本地脚本检索 Flutter、UX 和 Flat Design Mobile 规则。

采用的结论：

- Flutter async UI 不能只覆盖 success，必须覆盖 loading 和 error。
- Flutter 表单应使用 `Form`，提交时统一 validation。
- 输入必须有可见 label 和 helper text，不能只依赖 placeholder。
- 错误信息必须可见且靠近相关区域，提供恢复路径。
- 移动端触控目标至少 44/48dp，控件间距至少 8dp。
- 风格采用 Flat Design Mobile / Touch-first：层级主要依靠色块、间距、字体和清晰状态，不依赖复杂阴影、渐变或装饰。

## 错误处理

错误来源：

- 描述为空。
- service 抛出 `ConfigGenerationException`。
- service 返回的配置未通过 `MiniAppValidator`。

错误 UI 必须显示可理解的原因和 `重试`。retry 使用最近一次非空描述重新生成。

如果 service 返回非法配置，controller 不应保留 preview，也不应让 `MiniAppRenderer` 尝试解释未知结构。

## 测试策略

新增 controller 单元测试：

- 空描述进入 `error`。
- 待办、习惯、倒计时、记账关键词生成对应 type。
- 未识别描述回退 `todo_list`。
- service 抛错进入 `error`，且不保留 preview。
- service 返回非法 schema 时进入 `error`，且不保留 preview。

新增 widget 测试：

- `/generate` 路由能打开生成页。
- 初始显示 empty 状态。
- 输入描述点击生成后显示预览。
- 失败 service 注入时显示 error 和 retry。
- retry 会复用上次描述重新调用生成。

继续运行项目验证：

```powershell
flutter analyze
flutter test
git diff --check
```

## 非目标

本阶段不做：

- 保存配置。
- 小应用库页面替换。
- 本地 JSON 文件存储。
- 运行数据模型。
- 真实 AI 后端。
- 复杂对话式 revision。
- 平台级 deep link 或 auth guard。

## 后续阶段

完成本阶段后，下一阶段建议规划：

`预览 -> 保存 -> 应用库展示 -> 打开已保存小应用`

该阶段再引入 `core/storage`、`features/library` 和配置数据持久化。
