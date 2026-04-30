abstract interface class ConfigGenerationService {
  Future<Map<String, Object?>> generate(String description);
}

class ConfigGenerationException implements Exception {
  const ConfigGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
