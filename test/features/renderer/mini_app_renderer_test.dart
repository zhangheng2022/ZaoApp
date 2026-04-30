import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/renderer/mini_app_renderer.dart';
import 'package:zaoapp/features/renderer/renderer_registry.dart';

void main() {
  group('MiniAppRendererRegistry', () {
    test('advertises only MVP renderer types', () {
      expect(MiniAppRendererRegistry.supportedTypes, {
        'todo_list',
        'habit_tracker',
        'countdown',
        'expense_tracker',
      });
    });
  });

  group('MiniAppRenderer', () {
    testWidgets('dispatches valid todo list configs to the todo renderer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiniAppRenderer(
            config: {
              'id': 'todo_001',
              'schemaVersion': 1,
              'appVersion': 1,
              'name': 'Daily tasks',
              'type': 'todo_list',
            },
          ),
        ),
      );

      expect(find.text('Daily tasks'), findsOneWidget);
      expect(find.byKey(const ValueKey('todo_list_renderer')), findsOneWidget);
    });

    testWidgets('refuses to render invalid or unsupported configs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiniAppRenderer(
            config: {
              'id': 'custom_001',
              'schemaVersion': 1,
              'appVersion': 1,
              'name': 'Custom thing',
              'type': 'arbitrary_forui_widget',
            },
          ),
        ),
      );

      expect(find.text('Unsupported mini app configuration'), findsOneWidget);
      expect(find.text('Custom thing'), findsNothing);
    });
  });
}
