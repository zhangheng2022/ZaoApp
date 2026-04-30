import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genui/genui.dart';

import 'genui_mini_app_package.dart';
import 'genui_package_validator.dart';
import 'runtime_bridge_handler.dart';

class GenUiSurfaceRunner extends StatefulWidget {
  const GenUiSurfaceRunner({
    required this.package,
    this.bridgeHandler,
    this.onRetry,
    super.key,
  });

  final GenUiMiniAppPackage package;
  final RuntimeBridgeHandler? bridgeHandler;
  final VoidCallback? onRetry;

  @override
  State<GenUiSurfaceRunner> createState() => _GenUiSurfaceRunnerState();
}

class _GenUiSurfaceRunnerState extends State<GenUiSurfaceRunner> {
  A2uiMessageProcessor? _processor;
  late RuntimeBridgeHandler _bridgeHandler;
  GenUiPackageValidationResult? _validation;

  @override
  void initState() {
    super.initState();
    _bridgeHandler =
        widget.bridgeHandler ??
        RuntimeBridgeHandler(initialData: widget.package.runtimeData);
    _buildSurface();
  }

  @override
  void didUpdateWidget(covariant GenUiSurfaceRunner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.package != widget.package) {
      _buildSurface();
    }
  }

  @override
  void dispose() {
    _processor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validation = _validation;
    final processor = _processor;
    final surfaceId = validation?.surfaceId;

    if (validation == null || !validation.isValid || processor == null) {
      return GenUiSurfaceError(
        message: '无法运行这个 GenUI 小应用：${validation?.message ?? '未知错误'}',
        onRetry: widget.onRetry,
      );
    }

    return SingleChildScrollView(
      child: GenUiSurface(
        host: _BridgeAwareGenUiHost(processor, _bridgeHandler),
        surfaceId: surfaceId!,
        defaultBuilder: (_) => const Center(child: Text('正在加载 GenUI surface...')),
      ),
    );
  }

  void _buildSurface() {
    _processor?.dispose();
    final validation = GenUiPackageValidator.validate(widget.package);
    _validation = validation;
    if (!validation.isValid) {
      _processor = null;
      return;
    }

    final processor = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );
    try {
      for (final messageJson in widget.package.surfaceJson) {
        processor.handleMessage(A2uiMessage.fromJson(messageJson));
      }
      _processor = processor;
    } catch (_) {
      processor.dispose();
      _processor = null;
      _validation = const GenUiPackageValidationResult.invalid(
        '无法解析 GenUI surface。',
      );
    }
  }
}

class GenUiSurfaceError extends StatelessWidget {
  const GenUiSurfaceError({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          FButton(
            size: .lg,
            variant: .outline,
            onPress: onRetry,
            child: const Text('重试'),
          ),
        ],
      ],
    ),
  );
}

class _BridgeAwareGenUiHost implements GenUiHost {
  const _BridgeAwareGenUiHost(this._delegate, this._bridgeHandler);

  final A2uiMessageProcessor _delegate;
  final RuntimeBridgeHandler _bridgeHandler;

  @override
  Iterable<Catalog> get catalogs => _delegate.catalogs;

  @override
  Map<String, DataModel> get dataModels => _delegate.dataModels;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _delegate.surfaceUpdates;

  @override
  DataModel dataModelForSurface(String surfaceId) =>
      _delegate.dataModelForSurface(surfaceId);

  @override
  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) =>
      _delegate.getSurfaceNotifier(surfaceId);

  @override
  void handleUiEvent(UiEvent event) {
    if (event is UserActionEvent) {
      final action = event.name;
      if (RuntimeBridgeHandler.allowedActions.contains(action)) {
        _bridgeHandler.handle(action, event.context);
        return;
      }
    }
    _delegate.handleUiEvent(event);
  }
}
