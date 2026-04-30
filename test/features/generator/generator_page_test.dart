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

  testWidgets('opens text input when tapping the description field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: GeneratorPage(service: const MockConfigGenerationService()),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
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
