import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/genui_runtime/genui_surface_runner.dart';

import 'genui_test_fixtures.dart';

void main() {
  testWidgets('renders a persisted GenUI surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GenUiSurfaceRunner(package: validPackage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试小应用'), findsOneWidget);
    expect(find.text('由 GenUI surface 渲染'), findsOneWidget);
  });

  testWidgets('shows retry UI when the package is invalid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GenUiSurfaceRunner(
          package: validPackage(surfaceJson: const []),
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('无法运行'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
