import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../renderer/mini_app_renderer.dart';
import 'config_generation_service.dart';
import 'generation_session_controller.dart';
import 'mock_config_generation_service.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({
    this.service = const MockConfigGenerationService(),
    super.key,
  });

  final ConfigGenerationService service;

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final GenerationSessionController _session;

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
                    spacing: 16,
                    children: [
                      Text(
                        '创建小应用',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _GeneratorForm(
                        formKey: _formKey,
                        controller: _descriptionController,
                        loading: _session.isLoading,
                        onSubmit: _generate,
                      ),
                      _PreviewPanel(
                        status: _session.status,
                        errorMessage: _session.errorMessage,
                        previewConfig: _session.previewConfig,
                        onRetry: _session.isLoading ? null : _session.retry,
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
    await _session.generate(_descriptionController.text);
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
      spacing: 12,
      children: [
        FTextFormField.multiline(
          control: FTextFieldControl.managed(controller: controller),
          enabled: !loading,
          label: const Text('描述你想要的小应用'),
          hint: '例如：帮我做一个每日待办清单',
          description: const Text('描述一个待办、习惯、倒计时或记账工具。'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入小应用描述' : null,
        ),
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
    required this.previewConfig,
    required this.onRetry,
  });

  final GenerationSessionStatus status;
  final String? errorMessage;
  final Map<String, Object?>? previewConfig;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final config = previewConfig;

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
          GenerationSessionStatus.success when config != null =>
            MiniAppRenderer(config: config),
          GenerationSessionStatus.success => const MiniAppRenderError(),
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
      spacing: 8,
      children: [Text('还没有预览'), Text('输入描述并生成后，小应用会显示在这里。')],
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
    spacing: 12,
    children: [
      Text(message),
      FButton(
        size: .lg,
        variant: .outline,
        onPress: onRetry,
        child: const Text('重试'),
      ),
    ],
  );
}
