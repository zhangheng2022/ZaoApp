import 'dart:async';

import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';

import '../genui_runtime/genui_mini_app_package.dart';

abstract interface class GenUiGenerationService {
  Future<GenUiMiniAppPackage> generate(String prompt);
}

class GenUiGenerationException implements Exception {
  const GenUiGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseGenUiGenerationService implements GenUiGenerationService {
  FirebaseGenUiGenerationService({DateTime Function()? now}) : _now = now;

  final DateTime Function()? _now;

  @override
  Future<GenUiMiniAppPackage> generate(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const GenUiGenerationException('Prompt is empty.');
    }

    final generator = FirebaseAiContentGenerator(
      catalog: CoreCatalogItems.asCatalog(),
      systemInstruction:
          'Generate a compact mobile-first GenUI surface for ZaoApp. '
          'Use only GenUI A2UI tools and do not emit source code.',
    );
    final messages = <Map<String, Object?>>[];
    final errors = <ContentGeneratorError>[];

    late final StreamSubscription<A2uiMessage> messageSubscription;
    late final StreamSubscription<ContentGeneratorError> errorSubscription;
    messageSubscription = generator.a2uiMessageStream.listen((message) {
      final encoded = _encodeA2uiMessage(message);
      if (encoded != null) {
        messages.add(encoded);
      }
    });
    errorSubscription = generator.errorStream.listen(errors.add);

    try {
      await generator.sendRequest(UserMessage.text(trimmed));
    } finally {
      await messageSubscription.cancel();
      await errorSubscription.cancel();
      generator.dispose();
    }

    if (errors.isNotEmpty) {
      throw GenUiGenerationException(errors.first.error.toString());
    }
    if (messages.isEmpty) {
      throw const GenUiGenerationException('No GenUI surface was generated.');
    }

    final now = (_now ?? DateTime.now)().toUtc();
    return GenUiMiniAppPackage(
      id: 'genui_${now.microsecondsSinceEpoch}',
      schemaVersion: 1,
      appVersion: 1,
      name: _nameFromPrompt(trimmed),
      prompt: trimmed,
      surfaceJson: messages,
      runtimeData: const {},
      savedAt: now,
      updatedAt: now,
    );
  }

  Map<String, Object?>? _encodeA2uiMessage(A2uiMessage message) {
    return switch (message) {
      SurfaceUpdate() => {'surfaceUpdate': message.toJson()},
      BeginRendering() => {
        'beginRendering': {
          'surfaceId': message.surfaceId,
          'root': message.root,
          if (message.styles != null) 'styles': message.styles,
          if (message.catalogId != null) 'catalogId': message.catalogId,
        },
      },
      DataModelUpdate() => {
        'dataModelUpdate': {
          'surfaceId': message.surfaceId,
          if (message.path != null) 'path': message.path,
          'contents': message.contents,
        },
      },
      SurfaceDeletion() => {
        'deleteSurface': {'surfaceId': message.surfaceId},
      },
    };
  }

  String _nameFromPrompt(String prompt) {
    final normalized = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 18) {
      return normalized;
    }
    return normalized.substring(0, 18);
  }
}
