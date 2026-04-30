import 'package:genui/genui.dart';

import 'genui_mini_app_package.dart';

class GenUiPackageValidationResult {
  const GenUiPackageValidationResult._({
    required this.isValid,
    this.message,
    this.surfaceId,
  });

  const GenUiPackageValidationResult.valid({required String surfaceId})
    : this._(isValid: true, surfaceId: surfaceId);

  const GenUiPackageValidationResult.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String? message;
  final String? surfaceId;
}

abstract final class GenUiPackageValidator {
  static const supportedSchemaVersion = 1;

  static GenUiPackageValidationResult validate(GenUiMiniAppPackage package) {
    if (package.schemaVersion != supportedSchemaVersion) {
      return const GenUiPackageValidationResult.invalid(
        'Unsupported schemaVersion.',
      );
    }
    if (package.id.trim().isEmpty) {
      return const GenUiPackageValidationResult.invalid('Missing id.');
    }
    if (package.name.trim().isEmpty) {
      return const GenUiPackageValidationResult.invalid('Missing name.');
    }
    if (package.prompt.trim().isEmpty) {
      return const GenUiPackageValidationResult.invalid('Missing prompt.');
    }
    if (package.surfaceJson.isEmpty) {
      return const GenUiPackageValidationResult.invalid(
        'Missing surfaceJson.',
      );
    }

    String? surfaceId;
    try {
      for (final messageJson in package.surfaceJson) {
        final message = A2uiMessage.fromJson(messageJson);
        if (message is BeginRendering) {
          surfaceId ??= message.surfaceId;
        }
      }
    } catch (_) {
      return const GenUiPackageValidationResult.invalid(
        'Invalid A2UI surfaceJson.',
      );
    }

    if (surfaceId == null || surfaceId.trim().isEmpty) {
      return const GenUiPackageValidationResult.invalid(
        'surfaceJson must include beginRendering.',
      );
    }

    return GenUiPackageValidationResult.valid(surfaceId: surfaceId);
  }
}
