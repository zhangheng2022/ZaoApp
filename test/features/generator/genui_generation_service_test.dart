import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/generator/mock_genui_generation_service.dart';
import 'package:zaoapp/features/genui_runtime/genui_package_validator.dart';

void main() {
  test('mock generation returns a valid GenUI package', () async {
    final service = MockGenUiGenerationService(
      now: () => DateTime.utc(2026, 4, 30, 10),
    );

    final package = await service.generate('帮我做一个每日待办小应用');

    expect(package.prompt, '帮我做一个每日待办小应用');
    expect(package.surfaceJson, isNotEmpty);
    expect(GenUiPackageValidator.validate(package).isValid, isTrue);
  });
}
