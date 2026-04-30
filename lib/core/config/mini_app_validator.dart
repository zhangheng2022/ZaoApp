import 'package:json_schema/json_schema.dart';

import 'mini_app_schema.dart';

class MiniAppValidationResult {
  const MiniAppValidationResult({required this.isValid, required this.errors});

  final bool isValid;
  final List<String> errors;
}

abstract final class MiniAppValidator {
  static final JsonSchema _schema = JsonSchema.create(miniAppSchema);

  static MiniAppValidationResult validate(Map<String, Object?> config) {
    final result = _schema.validate(config);

    return MiniAppValidationResult(
      isValid: result.isValid,
      errors: [for (final error in result.errors) error.toString()],
    );
  }
}
