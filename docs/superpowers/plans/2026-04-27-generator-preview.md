# Generator Mock Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MVP front half flow: natural-language description -> mock JSON config -> client validation -> renderer preview.

**Architecture:** Add a `features/generator` module with a service interface, mock service, page-level `ChangeNotifier` controller, and single-page generator UI. The controller owns generation state and validates every returned config through `MiniAppValidator` before preview. Routing adds `/generate` while leaving the current library smoke route in place.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Forui 0.21.3, go_router, json_schema, flutter_test, mocktail.

---

## File Structure

- Create `lib/features/generator/config_generation_service.dart`: service contract and `ConfigGenerationException`.
- Create `lib/features/generator/mock_config_generation_service.dart`: keyword-based schemaVersion 1 config generator.
- Create `lib/features/generator/generation_session_controller.dart`: `ChangeNotifier` state holder and validation gate.
- Create `lib/features/generator/generator_page.dart`: Forui mobile-first single-page UI.
- Modify `lib/app/app_router.dart`: add `/generate` route and optional service injection through `createAppRouter`.
- Modify `lib/main.dart`: use `createAppRouter()` instead of the old top-level router instance.
- Create `test/features/generator/mock_config_generation_service_test.dart`: mock service behavior.
- Create `test/features/generator/generation_session_controller_test.dart`: controller state and validation behavior.
- Create `test/features/generator/generator_page_test.dart`: page UI states, success preview, error, retry.
- Modify `test/widget_test.dart`: assert `/generate` route renders the generator page.

## UI/UX Pro Max Requirements

Use the project-local skill `.agents/skills/ui-ux-pro-max` conclusions from the spec:

- Use `Form` and submit validation.
- Use visible label and helper text, not placeholder-only input.
- Cover empty, loading, success, error, and retry states.
- Disable the primary action while loading.
- Keep touch targets at least 44/48dp; use `FButton(size: .lg)` for the primary action.
- Use `LayoutBuilder` and constrained width so small phones, regular phones, tablets, and landscape do not overflow.
- Use Flat Design Mobile / Touch-first: clean blocks, clear spacing, no marketing hero, no emoji icons.

---

### Task 1: Mock Config Generation Service

**Files:**
- Create: `lib/features/generator/config_generation_service.dart`
- Create: `lib/features/generator/mock_config_generation_service.dart`
- Test: `test/features/generator/mock_config_generation_service_test.dart`

- [ ] **Step 1: Write failing tests for keyword mapping and fallback**

Create `test/features/generator/mock_config_generation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/generator/mock_config_generation_service.dart';

void main() {
  group('MockConfigGenerationService', () {
    late MockConfigGenerationService service;

    setUp(() {
      service = const MockConfigGenerationService();
    });

    test('generates todo list configs for todo descriptions', () async {
      final config = await service.generate('帮我做一个每日待办清单');

      expect(config['schemaVersion'], 1);
      expect(config['appVersion'], 1);
      expect(config['type'], 'todo_list');
      expect(config['name'], '待办清单');
      expect(config['fields'], isA<List<Object?>>());
    });

    test('generates habit tracker configs for habit descriptions', () async {
      final config = await service.generate('我想做一个习惯打卡工具');

      expect(config['type'], 'habit_tracker');
      expect(config['name'], '习惯打卡');
    });

    test('generates countdown configs for deadline descriptions', () async {
      final config = await service.generate('创建一个 deadline 倒计时');

      expect(config['type'], 'countdown');
      expect(config['name'], '倒计时');
    });

    test('generates expense tracker configs for money descriptions', () async {
      final config = await service.generate('做一个 money 记账工具');

      expect(config['type'], 'expense_tracker');
      expect(config['name'], '记账');
    });

    test('falls back to todo list configs for unknown descriptions', () async {
      final config = await service.generate('帮我做一个普通效率工具');

      expect(config['type'], 'todo_list');
      expect(config['name'], '待办清单');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
flutter test test\features\generator\mock_config_generation_service_test.dart
```

Expected: FAIL because `mock_config_generation_service.dart` does not exist.

- [ ] **Step 3: Implement the service contract**

Create `lib/features/generator/config_generation_service.dart`:

```dart
abstract interface class ConfigGenerationService {
  Future<Map<String, Object?>> generate(String description);
}

class ConfigGenerationException implements Exception {
  const ConfigGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
```

- [ ] **Step 4: Implement the mock service**

Create `lib/features/generator/mock_config_generation_service.dart`:

```dart
import 'config_generation_service.dart';

class MockConfigGenerationService implements ConfigGenerationService {
  const MockConfigGenerationService();

  @override
  Future<Map<String, Object?>> generate(String description) async {
    final normalized = description.toLowerCase();

    if (_containsAny(normalized, const ['习惯', '打卡', 'habit'])) {
      return _baseConfig(
        id: 'habit_mock',
        name: '习惯打卡',
        type: 'habit_tracker',
        fields: const [
          {'key': 'title', 'label': '习惯名称', 'type': 'text'},
          {'key': 'done', 'label': '今日完成', 'type': 'switch'},
        ],
      );
    }

    if (_containsAny(normalized, const ['倒计时', 'countdown', 'deadline'])) {
      return _baseConfig(
        id: 'countdown_mock',
        name: '倒计时',
        type: 'countdown',
        fields: const [
          {'key': 'title', 'label': '目标名称', 'type': 'text'},
          {'key': 'targetDate', 'label': '目标日期', 'type': 'date'},
        ],
      );
    }

    if (_containsAny(normalized, const ['记账', 'expense', 'money'])) {
      return _baseConfig(
        id: 'expense_mock',
        name: '记账',
        type: 'expense_tracker',
        fields: const [
          {'key': 'title', 'label': '项目', 'type': 'text'},
          {'key': 'amount', 'label': '金额', 'type': 'number'},
        ],
      );
    }

    return _baseConfig(
      id: 'todo_mock',
      name: '待办清单',
      type: 'todo_list',
      fields: const [
        {'key': 'title', 'label': '任务', 'type': 'text'},
        {'key': 'done', 'label': '完成', 'type': 'switch'},
      ],
    );
  }

  bool _containsAny(String source, List<String> keywords) =>
      keywords.any(source.contains);

  Map<String, Object?> _baseConfig({
    required String id,
    required String name,
    required String type,
    required List<Map<String, Object?>> fields,
  }) => {
    'id': id,
    'schemaVersion': 1,
    'appVersion': 1,
    'name': name,
    'type': type,
    'fields': fields,
  };
}
```

- [ ] **Step 5: Run tests to verify GREEN**

Run:

```powershell
flutter test test\features\generator\mock_config_generation_service_test.dart
```

Expected: PASS, all mock service tests pass.

- [ ] **Step 6: Commit Task 1**

```powershell
git add lib\features\generator\config_generation_service.dart lib\features\generator\mock_config_generation_service.dart test\features\generator\mock_config_generation_service_test.dart
git commit -m "Add mock config generation service"
```

---

### Task 2: Generation Session Controller

**Files:**
- Create: `lib/features/generator/generation_session_controller.dart`
- Test: `test/features/generator/generation_session_controller_test.dart`

- [ ] **Step 1: Write failing controller tests**

Create `test/features/generator/generation_session_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/generator/config_generation_service.dart';
import 'package:zaoapp/features/generator/generation_session_controller.dart';
import 'package:zaoapp/features/generator/mock_config_generation_service.dart';

void main() {
  group('GenerationSessionController', () {
    test('starts idle without preview or error', () {
      final controller = GenerationSessionController(
        service: const MockConfigGenerationService(),
      );

      expect(controller.status, GenerationSessionStatus.idle);
      expect(controller.previewConfig, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('rejects empty descriptions', () async {
      final controller = GenerationSessionController(
        service: const MockConfigGenerationService(),
      );

      await controller.generate('   ');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '请输入小应用描述');
      expect(controller.previewConfig, isNull);
    });

    test('stores preview config when generation and validation pass', () async {
      final controller = GenerationSessionController(
        service: const MockConfigGenerationService(),
      );

      await controller.generate('做一个习惯打卡工具');

      expect(controller.status, GenerationSessionStatus.success);
      expect(controller.previewConfig?['type'], 'habit_tracker');
      expect(controller.errorMessage, isNull);
    });

    test('enters error when the service throws', () async {
      final controller = GenerationSessionController(
        service: const _FailingGenerationService(),
      );

      await controller.generate('做一个待办工具');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '生成失败，请重试');
      expect(controller.previewConfig, isNull);
    });

    test('rejects invalid configs returned by the service', () async {
      final controller = GenerationSessionController(
        service: const _InvalidGenerationService(),
      );

      await controller.generate('做一个未知工具');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '生成的配置不符合当前版本要求');
      expect(controller.previewConfig, isNull);
    });

    test('retry reuses the last valid description', () async {
      final service = _RecoveringGenerationService();
      final controller = GenerationSessionController(service: service);

      await controller.generate('做一个待办工具');
      expect(controller.status, GenerationSessionStatus.error);

      await controller.retry();

      expect(service.calls, 2);
      expect(controller.status, GenerationSessionStatus.success);
      expect(controller.previewConfig?['type'], 'todo_list');
    });
  });
}

class _FailingGenerationService implements ConfigGenerationService {
  const _FailingGenerationService();

  @override
  Future<Map<String, Object?>> generate(String description) {
    throw const ConfigGenerationException('boom');
  }
}

class _InvalidGenerationService implements ConfigGenerationService {
  const _InvalidGenerationService();

  @override
  Future<Map<String, Object?>> generate(String description) async => {
    'id': 'bad',
    'schemaVersion': 99,
    'appVersion': 1,
    'name': 'Bad',
    'type': 'unknown',
  };
}

class _RecoveringGenerationService implements ConfigGenerationService {
  int calls = 0;

  @override
  Future<Map<String, Object?>> generate(String description) async {
    calls += 1;
    if (calls == 1) {
      throw const ConfigGenerationException('first call fails');
    }
    return {
      'id': 'todo_mock',
      'schemaVersion': 1,
      'appVersion': 1,
      'name': '待办清单',
      'type': 'todo_list',
    };
  }
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
flutter test test\features\generator\generation_session_controller_test.dart
```

Expected: FAIL because `generation_session_controller.dart` does not exist.

- [ ] **Step 3: Implement the controller**

Create `lib/features/generator/generation_session_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../../core/config/mini_app_validator.dart';
import 'config_generation_service.dart';

enum GenerationSessionStatus { idle, loading, success, error }

class GenerationSessionController extends ChangeNotifier {
  GenerationSessionController({required ConfigGenerationService service})
    : _service = service;

  final ConfigGenerationService _service;

  GenerationSessionStatus _status = GenerationSessionStatus.idle;
  Map<String, Object?>? _previewConfig;
  String? _errorMessage;
  String? _lastDescription;

  GenerationSessionStatus get status => _status;
  Map<String, Object?>? get previewConfig => _previewConfig;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == GenerationSessionStatus.loading;

  Future<void> generate(String description) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }

    _lastDescription = trimmed;
    _status = GenerationSessionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final config = await _service.generate(trimmed);
      final validation = MiniAppValidator.validate(config);
      if (!validation.isValid) {
        _setError('生成的配置不符合当前版本要求');
        return;
      }

      _previewConfig = config;
      _status = GenerationSessionStatus.success;
      _errorMessage = null;
      notifyListeners();
    } on ConfigGenerationException catch (_) {
      _setError('生成失败，请重试');
    } catch (_) {
      _setError('生成失败，请重试');
    }
  }

  Future<void> retry() async {
    final description = _lastDescription;
    if (description == null || description.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }
    await generate(description);
  }

  void _setError(String message) {
    _previewConfig = null;
    _status = GenerationSessionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run controller tests to verify GREEN**

Run:

```powershell
flutter test test\features\generator\generation_session_controller_test.dart
```

Expected: PASS, all controller tests pass.

- [ ] **Step 5: Run service and controller tests together**

Run:

```powershell
flutter test test\features\generator\mock_config_generation_service_test.dart test\features\generator\generation_session_controller_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

```powershell
git add lib\features\generator\generation_session_controller.dart test\features\generator\generation_session_controller_test.dart
git commit -m "Add generation session controller"
```

---

### Task 3: Generator Page UI

**Files:**
- Create: `lib/features/generator/generator_page.dart`
- Test: `test/features/generator/generator_page_test.dart`

- [ ] **Step 1: Write failing widget tests for UI states**

Create `test/features/generator/generator_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:zaoapp/features/generator/config_generation_service.dart';
import 'package:zaoapp/features/generator/generator_page.dart';
import 'package:zaoapp/features/generator/mock_config_generation_service.dart';

void main() {
  testWidgets('shows the initial empty state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(service: const MockConfigGenerationService()),
      ),
    );

    expect(find.text('创建小应用'), findsOneWidget);
    expect(find.text('描述你想要的小应用'), findsOneWidget);
    expect(find.text('还没有预览'), findsOneWidget);
    expect(find.text('生成预览'), findsOneWidget);
  });

  testWidgets('generates and previews a mini app config', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(service: const MockConfigGenerationService()),
      ),
    );

    await tester.enterText(find.byType(EditableText), '帮我做一个待办清单');
    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();

    expect(find.text('待办清单'), findsOneWidget);
    expect(find.byKey(const ValueKey('todo_list_renderer')), findsOneWidget);
  });

  testWidgets('shows validation error for empty input', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(service: const MockConfigGenerationService()),
      ),
    );

    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();

    expect(find.text('请输入小应用描述'), findsOneWidget);
  });

  testWidgets('shows service errors and retries with the last description', (
    tester,
  ) async {
    final service = _RecoveringGenerationService();
    await tester.pumpWidget(_TestApp(child: GeneratorPage(service: service)));

    await tester.enterText(find.byType(EditableText), '做一个待办工具');
    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();

    expect(find.text('生成失败，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('待办清单'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FThemes.neutral.dark.touch;
    return MaterialApp(
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: theme.toApproximateMaterialTheme(),
      home: FTheme(data: theme, child: child),
    );
  }
}

class _RecoveringGenerationService implements ConfigGenerationService {
  int calls = 0;

  @override
  Future<Map<String, Object?>> generate(String description) async {
    calls += 1;
    if (calls == 1) {
      throw const ConfigGenerationException('first call fails');
    }
    return {
      'id': 'todo_mock',
      'schemaVersion': 1,
      'appVersion': 1,
      'name': '待办清单',
      'type': 'todo_list',
    };
  }
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
flutter test test\features\generator\generator_page_test.dart
```

Expected: FAIL because `generator_page.dart` does not exist.

- [ ] **Step 3: Implement the generator page**

Create `lib/features/generator/generator_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../renderer/mini_app_renderer.dart';
import 'config_generation_service.dart';
import 'generation_session_controller.dart';
import 'mock_config_generation_service.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({
    this.service = const MockConfigGenerationService(),
    super.key,
  });

  final ConfigGenerationService service;

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final GenerationSessionController _session;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _session = GenerationSessionController(service: widget.service);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FScaffold(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 700 ? 640.0 : double.infinity;

          return AnimatedBuilder(
            animation: _session,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      Text(
                        '创建小应用',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _GeneratorForm(
                        formKey: _formKey,
                        controller: _descriptionController,
                        loading: _session.isLoading,
                        onSubmit: _generate,
                      ),
                      _PreviewPanel(
                        status: _session.status,
                        errorMessage: _session.errorMessage,
                        previewConfig: _session.previewConfig,
                        onRetry: _session.isLoading ? null : _session.retry,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await _session.generate(_descriptionController.text);
  }
}

class _GeneratorForm extends StatelessWidget {
  const _GeneratorForm({
    required this.formKey,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FTextFormField.multiline(
          control: FTextFieldControl.managed(controller: controller),
          enabled: !loading,
          label: const Text('描述你想要的小应用'),
          hint: '例如：帮我做一个每日待办清单',
          description: const Text('描述一个待办、习惯、倒计时或记账工具。'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入小应用描述' : null,
        ),
        FButton(
          size: .lg,
          onPress: loading ? null : onSubmit,
          child: Text(loading ? '生成中...' : '生成预览'),
        ),
      ],
    ),
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.status,
    required this.errorMessage,
    required this.previewConfig,
    required this.onRetry,
  });

  final GenerationSessionStatus status;
  final String? errorMessage;
  final Map<String, Object?>? previewConfig;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final config = previewConfig;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (status) {
          GenerationSessionStatus.idle => const _EmptyPreview(),
          GenerationSessionStatus.loading => const _LoadingPreview(),
          GenerationSessionStatus.success when config != null =>
            MiniAppRenderer(config: config),
          GenerationSessionStatus.success => const MiniAppRenderError(),
          GenerationSessionStatus.error => _ErrorPreview(
            message: errorMessage ?? '生成失败，请重试',
            onRetry: onRetry,
          ),
        },
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text('还没有预览'),
        Text('输入描述并生成后，小应用会显示在这里。'),
      ],
    ),
  );
}

class _LoadingPreview extends StatelessWidget {
  const _LoadingPreview();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('正在生成预览...'));
}

class _ErrorPreview extends StatelessWidget {
  const _ErrorPreview({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      Text(message),
      FButton(
        size: .lg,
        variant: .outline,
        onPress: onRetry,
        child: const Text('重试'),
      ),
    ],
  );
}
```

- [ ] **Step 4: Run widget tests to verify GREEN**

Run:

```powershell
flutter test test\features\generator\generator_page_test.dart
```

Expected: PASS, generator page widget tests pass.

- [ ] **Step 5: Commit Task 3**

```powershell
git add lib\features\generator\generator_page.dart test\features\generator\generator_page_test.dart
git commit -m "Add generator preview page"
```

---

### Task 4: Router Integration

**Files:**
- Modify: `lib/app/app_router.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing route test**

Add this test to `test/widget_test.dart`:

```dart
testWidgets('Generator route renders the generator page', (
  WidgetTester tester,
) async {
  await tester.pumpWidget(const Application());

  final context = tester.element(find.byType(SmokeCounter));
  GoRouter.of(context).go('/generate');
  await tester.pumpAndSettle();

  expect(find.text('创建小应用'), findsOneWidget);
  expect(find.text('生成预览'), findsOneWidget);
});
```

- [ ] **Step 2: Run route test to verify RED**

Run:

```powershell
flutter test test\widget_test.dart
```

Expected: FAIL because `/generate` still renders the router error page.

- [ ] **Step 3: Update router constants and route factory**

Modify `lib/app/app_router.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/generator/config_generation_service.dart';
import '../features/generator/generator_page.dart';
import '../features/generator/mock_config_generation_service.dart';
import '../shared/widgets/smoke_counter.dart';

abstract final class AppRouteNames {
  static const library = 'library';
  static const generator = 'generator';
}

abstract final class AppRoutePaths {
  static const library = '/';
  static const generator = '/generate';
}

GoRouter createAppRouter({
  ConfigGenerationService generatorService =
      const MockConfigGenerationService(),
}) => GoRouter(
  initialLocation: AppRoutePaths.library,
  routes: [
    GoRoute(
      path: AppRoutePaths.library,
      name: AppRouteNames.library,
      builder: (context, state) => const FScaffold(
        // Temporary smoke-test screen before the ZaoApp feature shell is built.
        child: SmokeCounter(),
      ),
    ),
    GoRoute(
      path: AppRoutePaths.generator,
      name: AppRouteNames.generator,
      builder: (context, state) => GeneratorPage(service: generatorService),
    ),
  ],
  errorBuilder: (context, state) =>
      const FScaffold(child: Center(child: Text('Page not found'))),
);

final GoRouter appRouter = createAppRouter();
```

- [ ] **Step 4: Keep `main.dart` using the router**

No behavior change is required if `main.dart` still imports `appRouter`. If you choose to make router creation explicit, change this line:

```dart
routerConfig: appRouter,
```

to:

```dart
routerConfig: createAppRouter(),
```

Do not do both unless tests require it.

- [ ] **Step 5: Run route tests to verify GREEN**

Run:

```powershell
flutter test test\widget_test.dart
```

Expected: PASS, existing smoke tests and `/generate` route test pass.

- [ ] **Step 6: Commit Task 4**

```powershell
git add lib\app\app_router.dart lib\main.dart test\widget_test.dart
git commit -m "Wire generator route"
```

---

### Task 5: Full Verification and UI Quality Gate

**Files:**
- Review all changed files from Tasks 1-4.

- [ ] **Step 1: Format changed Dart files**

Run:

```powershell
dart format lib test
```

Expected: command exits 0 and formats any changed files.

- [ ] **Step 2: Run static analysis**

Run:

```powershell
flutter analyze
```

Expected: `No issues found`.

- [ ] **Step 3: Run full test suite**

Run:

```powershell
flutter test
```

Expected: all tests pass, including existing renderer tests and new generator tests.

- [ ] **Step 4: Run whitespace check**

Run:

```powershell
git diff --check
```

Expected: no output, exit code 0.

- [ ] **Step 5: Manually inspect UI quality requirements**

Run the app:

```powershell
flutter run -d windows
```

Open `/generate` if the app starts at `/`. Check these states:

- Initial empty state shows `还没有预览`.
- Empty submit shows `请输入小应用描述`.
- Valid submit shows generated preview.
- Loading disables `生成预览`.
- Injected failing service is covered by widget tests, not by a user-facing trigger.
- No horizontal overflow at narrow window width.
- Primary button remains at least 48dp high through `FButton(size: .lg)`.
- Form has visible label and helper text.

- [ ] **Step 6: Final commit if formatting or verification caused changes**

If `dart format` changed files after the task commits:

```powershell
git add lib test
git commit -m "Polish generator preview implementation"
```

If no files changed, do not create an empty commit.

- [ ] **Step 7: Report final verification**

Report the exact results of:

```powershell
flutter analyze
flutter test
git diff --check
git status --short
```

Expected final state: verification passes and `git status --short` is empty.

---

## Self-Review

- Spec coverage: Tasks cover service interface, mock mapping, controller state, validation gate, `/generate` route, single-page UI, empty/loading/success/error/retry, and test coverage.
- Scope: Plan excludes save, storage, library replacement, runtime data, real backend, revision flow, and deep links.
- UI quality: Plan includes `ui-ux-pro-max` conclusions, Forui form components, touch target sizing, loading/error feedback, and responsive constraints.
- Type consistency: `ConfigGenerationService.generate(String)` returns `Future<Map<String, Object?>>`; controller and page use the same type; route injection uses the same service interface.
