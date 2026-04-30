import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/core/config/mini_app_validator.dart';

void main() {
  group('MiniAppValidator', () {
    test('accepts a schema version 1 todo list configuration', () {
      final result = MiniAppValidator.validate({
        'id': 'todo_001',
        'schemaVersion': 1,
        'appVersion': 1,
        'name': 'Daily tasks',
        'type': 'todo_list',
        'fields': [
          {'key': 'title', 'label': 'Title', 'type': 'text'},
          {'key': 'done', 'label': 'Done', 'type': 'switch'},
        ],
      });

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rejects unsupported schema versions before rendering', () {
      final result = MiniAppValidator.validate({
        'id': 'todo_001',
        'schemaVersion': 2,
        'appVersion': 1,
        'name': 'Daily tasks',
        'type': 'todo_list',
      });

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('rejects app types outside the renderer whitelist', () {
      final result = MiniAppValidator.validate({
        'id': 'custom_001',
        'schemaVersion': 1,
        'appVersion': 1,
        'name': 'Custom thing',
        'type': 'arbitrary_forui_widget',
      });

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });
  });
}
