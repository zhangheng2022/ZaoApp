import 'package:flutter/foundation.dart';

import '../../core/config/mini_app_validator.dart';
import 'config_generation_service.dart';

enum GenerationSessionStatus { idle, loading, success, error }

class GenerationSessionController extends ChangeNotifier {
  GenerationSessionController({required ConfigGenerationService service})
    : _service = service;

  final ConfigGenerationService _service;

  GenerationSessionStatus _status = GenerationSessionStatus.idle;
  Map<String, Object?>? _previewConfig;
  String? _errorMessage;
  String? _lastDescription;

  GenerationSessionStatus get status => _status;
  Map<String, Object?>? get previewConfig => _previewConfig;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == GenerationSessionStatus.loading;

  Future<void> generate(String description) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }

    _lastDescription = trimmed;
    _status = GenerationSessionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final config = await _service.generate(trimmed);
      final validation = MiniAppValidator.validate(config);
      if (!validation.isValid) {
        _setError('生成的配置不符合当前版本要求');
        return;
      }

      _previewConfig = config;
      _status = GenerationSessionStatus.success;
      _errorMessage = null;
      notifyListeners();
    } on ConfigGenerationException catch (_) {
      _setError('生成失败，请重试');
    } catch (_) {
      _setError('生成失败，请重试');
    }
  }

  Future<void> retry() async {
    final description = _lastDescription;
    if (description == null || description.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }
    await generate(description);
  }

  void _setError(String message) {
    _previewConfig = null;
    _status = GenerationSessionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
