import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/generator/generation_session_controller.dart';
import 'package:zaoapp/features/generator/genui_generation_service.dart';
import 'package:zaoapp/features/generator/mock_genui_generation_service.dart';
import 'package:zaoapp/features/genui_runtime/genui_mini_app_package.dart';

import '../genui_runtime/genui_test_fixtures.dart';

void main() {
  group('GenerationSessionController', () {
    test('starts idle without preview or error', () {
      final controller = GenerationSessionController(
        service: const MockGenUiGenerationService(),
      );

      expect(controller.status, GenerationSessionStatus.idle);
      expect(controller.previewPackage, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('rejects empty prompts', () async {
      final controller = GenerationSessionController(
        service: const MockGenUiGenerationService(),
      );

      await controller.generate('   ');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '请输入小应用描述');
      expect(controller.previewPackage, isNull);
    });

    test('stores preview package when generation and validation pass', () async {
      final controller = GenerationSessionController(
        service: const MockGenUiGenerationService(),
      );

      await controller.generate('做一个习惯打卡工具');

      expect(controller.status, GenerationSessionStatus.success);
      expect(controller.previewPackage?.name, '习惯打卡');
      expect(controller.previewPackage?.surfaceJson, isNotEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('enters error when the service throws', () async {
      final controller = GenerationSessionController(
        service: const _FailingGenerationService(),
      );

      await controller.generate('做一个待办工具');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '生成失败，请重试');
      expect(controller.previewPackage, isNull);
    });

    test('rejects invalid GenUI packages returned by the service', () async {
      final controller = GenerationSessionController(
        service: const _InvalidGenerationService(),
      );

      await controller.generate('做一个未知工具');

      expect(controller.status, GenerationSessionStatus.error);
      expect(controller.errorMessage, '生成的 GenUI surface 不符合当前版本要求');
      expect(controller.previewPackage, isNull);
    });

    test('retry reuses the last valid prompt', () async {
      final service = _RecoveringGenerationService();
      final controller = GenerationSessionController(service: service);

      await controller.generate('做一个待办工具');
      expect(controller.status, GenerationSessionStatus.error);

      await controller.retry();

      expect(service.calls, 2);
      expect(controller.status, GenerationSessionStatus.success);
      expect(controller.previewPackage?.name, '恢复的小应用');
    });
  });
}

class _FailingGenerationService implements GenUiGenerationService {
  const _FailingGenerationService();

  @override
  Future<GenUiMiniAppPackage> generate(String prompt) {
    throw const GenUiGenerationException('boom');
  }
}

class _InvalidGenerationService implements GenUiGenerationService {
  const _InvalidGenerationService();

  @override
  Future<GenUiMiniAppPackage> generate(String prompt) async =>
      validPackage(surfaceJson: const []);
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
