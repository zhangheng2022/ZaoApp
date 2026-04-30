import 'package:flutter/widgets.dart';

import '../../core/config/mini_app_validator.dart';
import 'renderer_registry.dart';

class MiniAppRenderer extends StatelessWidget {
  const MiniAppRenderer({
    required this.config,
    this.registry = const MiniAppRendererRegistry(),
    super.key,
  });

  final Map<String, Object?> config;
  final MiniAppRendererRegistry registry;

  @override
  Widget build(BuildContext context) {
    final validation = MiniAppValidator.validate(config);
    if (!validation.isValid) {
      return const MiniAppRenderError();
    }

    return registry.build(context, config);
  }
}

class MiniAppRenderError extends StatelessWidget {
  const MiniAppRenderError({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Unsupported mini app configuration'));
}
