import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../genui_runtime/genui_mini_app_package.dart';
import '../genui_runtime/genui_surface_runner.dart';
import '../library/genui_mini_app_repository.dart';
import 'generation_session_controller.dart';
import 'genui_generation_service.dart';
import 'mock_genui_generation_service.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({
    this.service = const MockGenUiGenerationService(),
    required this.repository,
    super.key,
  });

  final GenUiGenerationService service;
  final GenUiMiniAppRepository repository;

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final GenerationSessionController _session;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _session = GenerationSessionController(service: widget.service);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FScaffold(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 700
              ? 640.0
              : double.infinity;

          return AnimatedBuilder(
            animation: _session,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('创建小应用', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      _GeneratorForm(
                        formKey: _formKey,
                        controller: _descriptionController,
                        loading: _session.isLoading,
                        onSubmit: _generate,
                      ),
                      const SizedBox(height: 16),
                      _PreviewPanel(
                        status: _session.status,
                        errorMessage: _session.errorMessage,
                        previewPackage: _session.previewPackage,
                        saving: _saving,
                        saveError: _saveError,
                        onRetry: _session.isLoading ? null : _session.retry,
                        onSave: _session.previewPackage == null || _saving
                            ? null
                            : () => _save(_session.previewPackage!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saveError = null);
    await _session.generate(_descriptionController.text);
  }

  Future<void> _save(GenUiMiniAppPackage package) async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.repository.save(package);
      if (mounted) {
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = '保存失败，请重试');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _GeneratorForm extends StatelessWidget {
  const _GeneratorForm({
    required this.formKey,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextFormField.multiline(
          control: FTextFieldControl.managed(controller: controller),
          enabled: !loading,
          label: const Text('描述你想要的小应用'),
          hint: '例如：帮我做一个每日待办清单',
          description: const Text('ZaoApp 会生成并保存 GenUI surface，不再使用内置 renderer。'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入小应用描述' : null,
        ),
        const SizedBox(height: 12),
        FButton(
          size: .lg,
          onPress: loading ? null : onSubmit,
          child: Text(loading ? '生成中...' : '生成预览'),
        ),
      ],
    ),
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.status,
    required this.errorMessage,
    required this.previewPackage,
    required this.saving,
    required this.saveError,
    required this.onRetry,
    required this.onSave,
  });

  final GenerationSessionStatus status;
  final String? errorMessage;
  final GenUiMiniAppPackage? previewPackage;
  final bool saving;
  final String? saveError;
  final VoidCallback? onRetry;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final package = previewPackage;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (status) {
          GenerationSessionStatus.idle => const _EmptyPreview(),
          GenerationSessionStatus.loading => const _LoadingPreview(),
          GenerationSessionStatus.success when package != null => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 260, child: GenUiSurfaceRunner(package: package)),
              const SizedBox(height: 12),
              if (saveError != null) ...[
                Text(saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
              ],
              FButton(
                size: .lg,
                onPress: onSave,
                child: Text(saving ? '保存中...' : '保存小应用'),
              ),
            ],
          ),
          GenerationSessionStatus.success => const GenUiSurfaceError(
            message: '无法运行生成的 GenUI surface。',
          ),
          GenerationSessionStatus.error => _ErrorPreview(
            message: errorMessage ?? '生成失败，请重试',
            onRetry: onRetry,
          ),
        },
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('还没有预览'),
        SizedBox(height: 8),
        Text('输入描述并生成后，小应用会作为 GenUI surface 显示在这里。'),
      ],
    ),
  );
}

class _LoadingPreview extends StatelessWidget {
  const _LoadingPreview();

  @override
  Widget build(BuildContext context) => const Center(child: Text('正在生成预览...'));
}

class _ErrorPreview extends StatelessWidget {
  const _ErrorPreview({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(message),
      const SizedBox(height: 12),
      FButton(
        size: .lg,
        variant: .outline,
        onPress: onRetry,
        child: const Text('重试'),
      ),
    ],
  );
}
