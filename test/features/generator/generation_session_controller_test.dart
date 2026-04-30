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
