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
