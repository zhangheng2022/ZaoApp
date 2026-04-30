import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/genui_runtime/genui_package_validator.dart';

import 'genui_test_fixtures.dart';

void main() {
  test('accepts a package with a parseable GenUI surface', () {
    final result = GenUiPackageValidator.validate(validPackage());

    expect(result.isValid, isTrue);
    expect(result.surfaceId, 'surface_test');
  });

  test('rejects packages without surfaceJson', () {
    final result = GenUiPackageValidator.validate(
      validPackage(surfaceJson: const []),
    );

    expect(result.isValid, isFalse);
    expect(result.message, contains('surfaceJson'));
  });

  test('rejects unsupported schema versions', () {
    final package = validPackage().copyWith(schemaVersion: 2);

    final result = GenUiPackageValidator.validate(package);

    expect(result.isValid, isFalse);
    expect(result.message, contains('schemaVersion'));
  });

  test('rejects unknown A2UI message shapes', () {
    final package = validPackage(
      surfaceJson: const [
        {
          'unknown': {'surfaceId': 'surface_test'},
        },
      ],
    );

    final result = GenUiPackageValidator.validate(package);

    expect(result.isValid, isFalse);
    expect(result.message, contains('A2UI'));
  });
}
