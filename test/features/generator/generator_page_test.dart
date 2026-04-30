import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:zaoapp/features/generator/generator_page.dart';
import 'package:zaoapp/features/generator/genui_generation_service.dart';
import 'package:zaoapp/features/generator/mock_genui_generation_service.dart';
import 'package:zaoapp/features/genui_runtime/genui_mini_app_package.dart';
import 'package:zaoapp/features/library/genui_mini_app_repository.dart';

import '../genui_runtime/genui_test_fixtures.dart';

void main() {
  testWidgets('shows the initial empty state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(
          service: const MockGenUiGenerationService(),
          repository: _MemoryRepository(),
        ),
      ),
    );

    expect(find.text('创建小应用'), findsOneWidget);
    expect(find.text('描述你想要的小应用'), findsOneWidget);
    expect(find.text('还没有预览'), findsOneWidget);
    expect(find.text('生成预览'), findsOneWidget);
  });

  testWidgets('opens text input when tapping the description field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(
          service: const MockGenUiGenerationService(),
          repository: _MemoryRepository(),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('generates and previews a GenUI mini app package', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(
          service: const MockGenUiGenerationService(),
          repository: _MemoryRepository(),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '帮我做一个每日待办清单');
    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();

    expect(find.text('待办清单'), findsOneWidget);
    expect(find.text('保存小应用'), findsOneWidget);
  });

  testWidgets('shows validation error for empty input', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(
          service: const MockGenUiGenerationService(),
          repository: _MemoryRepository(),
        ),
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
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(service: service, repository: _MemoryRepository()),
      ),
    );

    await tester.enterText(find.byType(EditableText), '做一个待办工具');
    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();

    expect(find.text('生成失败，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('测试小应用'), findsOneWidget);
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

class _RecoveringGenerationService implements GenUiGenerationService {
  int calls = 0;

  @override
  Future<GenUiMiniAppPackage> generate(String prompt) async {
    calls += 1;
    if (calls == 1) {
      throw const GenUiGenerationException('first call fails');
    }
    return validPackage(name: '恢复的小应用', prompt: prompt);
  }
}

class _MemoryRepository implements GenUiMiniAppRepository {
  final _packages = <GenUiMiniAppPackage>[];

  @override
  Future<GenUiMiniAppPackage?> findById(String id) async {
    for (final package in _packages) {
      if (package.id == id) {
        return package;
      }
    }
    return null;
  }

  @override
  Future<List<GenUiMiniAppPackage>> list() async => List.of(_packages);

  @override
  Future<void> save(GenUiMiniAppPackage package) async {
    _packages.add(package);
  }
}
