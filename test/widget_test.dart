import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:zaoapp/app/app_router.dart';
import 'package:zaoapp/features/generator/mock_genui_generation_service.dart';
import 'package:zaoapp/features/genui_runtime/genui_mini_app_package.dart';
import 'package:zaoapp/features/genui_runtime/genui_surface_runner.dart';
import 'package:zaoapp/features/library/app_library_page.dart';
import 'package:zaoapp/features/library/genui_mini_app_repository.dart';

import 'features/genui_runtime/genui_test_fixtures.dart';

void main() {
  testWidgets('router renders the app library home page', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryRepository();
    await tester.pumpWidget(_RoutedApp(repository: repository));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppLibraryPage));
    expect(GoRouterState.of(context).matchedLocation, '/');

    expect(find.text('我的小应用'), findsOneWidget);
    expect(find.text('还没有小应用'), findsOneWidget);
    expect(find.text('创建小应用'), findsOneWidget);
  });

  testWidgets('unknown routes render the router error screen', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryRepository();
    await tester.pumpWidget(_RoutedApp(repository: repository));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppLibraryPage));
    GoRouter.of(context).go('/missing-route');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('create generate and save returns to library with package', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryRepository();
    await tester.pumpWidget(_RoutedApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建小应用'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '帮我做一个每日待办清单');
    await tester.tap(find.text('生成预览'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存小应用'));
    await tester.tap(find.text('保存小应用'));
    await tester.pumpAndSettle();

    expect(find.byType(AppLibraryPage), findsOneWidget);
    expect(find.text('待办清单'), findsOneWidget);
    expect(repository.savedCount, 1);
  });

  testWidgets('library item opens the GenUI runner route', (tester) async {
    final repository = _MemoryRepository([validPackage(name: '已保存应用')]);
    await tester.pumpWidget(_RoutedApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(GenUiSurfaceRunner), findsOneWidget);
    expect(find.text('测试小应用'), findsOneWidget);
  });
}

class _RoutedApp extends StatelessWidget {
  const _RoutedApp({required this.repository});

  final GenUiMiniAppRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = FThemes.neutral.dark.touch;
    return MaterialApp.router(
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: theme.toApproximateMaterialTheme(),
      builder: (_, child) => FTheme(
        data: theme,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      routerConfig: createAppRouter(
        generatorService: const MockGenUiGenerationService(),
        repository: repository,
      ),
    );
  }
}

class _MemoryRepository implements GenUiMiniAppRepository {
  _MemoryRepository([List<GenUiMiniAppPackage> initial = const []])
    : _packages = List.of(initial);

  final List<GenUiMiniAppPackage> _packages;

  int get savedCount => _packages.length;

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
    _packages
      ..removeWhere((item) => item.id == package.id)
      ..add(package);
  }
}
