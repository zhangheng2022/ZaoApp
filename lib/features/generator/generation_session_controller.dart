import 'package:flutter/foundation.dart';

import '../genui_runtime/genui_mini_app_package.dart';
import '../genui_runtime/genui_package_validator.dart';
import 'genui_generation_service.dart';

enum GenerationSessionStatus { idle, loading, success, error }

class GenerationSessionController extends ChangeNotifier {
  GenerationSessionController({required GenUiGenerationService service})
    : _service = service;

  final GenUiGenerationService _service;

  GenerationSessionStatus _status = GenerationSessionStatus.idle;
  GenUiMiniAppPackage? _previewPackage;
  String? _errorMessage;
  String? _lastPrompt;

  GenerationSessionStatus get status => _status;
  GenUiMiniAppPackage? get previewPackage => _previewPackage;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == GenerationSessionStatus.loading;

  Future<void> generate(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }

    _lastPrompt = trimmed;
    _status = GenerationSessionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final package = await _service.generate(trimmed);
      final validation = GenUiPackageValidator.validate(package);
      if (!validation.isValid) {
        _setError('生成的 GenUI surface 不符合当前版本要求');
        return;
      }

      _previewPackage = package;
      _status = GenerationSessionStatus.success;
      _errorMessage = null;
      notifyListeners();
    } on GenUiGenerationException catch (_) {
      _setError('生成失败，请重试');
    } catch (_) {
      _setError('生成失败，请重试');
    }
  }

  Future<void> retry() async {
    final prompt = _lastPrompt;
    if (prompt == null || prompt.isEmpty) {
      _setError('请输入小应用描述');
      return;
    }
    await generate(prompt);
  }

  void _setError(String message) {
    _previewPackage = null;
    _status = GenerationSessionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
