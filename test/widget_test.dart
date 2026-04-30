import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zaoapp/features/library/app_library_page.dart';
import 'package:zaoapp/main.dart';

void main() {
  testWidgets('Application renders the routed app library home page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Application());

    final context = tester.element(find.byType(AppLibraryPage));
    expect(GoRouterState.of(context).matchedLocation, '/');

    expect(find.text('我的小应用'), findsOneWidget);
    expect(find.text('还没有小应用'), findsOneWidget);
    expect(find.text('创建小应用'), findsOneWidget);
  });

  testWidgets('Unknown routes render the router error screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Application());

    final context = tester.element(find.byType(AppLibraryPage));
    GoRouter.of(context).go('/missing-route');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('Create action opens the generator page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Application());

    await tester.tap(find.text('创建小应用'));
    await tester.pumpAndSettle();

    expect(find.text('创建小应用'), findsOneWidget);
    expect(find.text('生成预览'), findsOneWidget);
  });
}
