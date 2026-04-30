import '../genui_runtime/genui_mini_app_package.dart';
import 'genui_generation_service.dart';

class MockGenUiGenerationService implements GenUiGenerationService {
  const MockGenUiGenerationService({DateTime Function()? now}) : _now = now;

  final DateTime Function()? _now;

  @override
  Future<GenUiMiniAppPackage> generate(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const GenUiGenerationException('Prompt is empty.');
    }

    final now = (_now ?? DateTime.now)().toUtc();
    final title = _titleFromPrompt(trimmed);
    return GenUiMiniAppPackage(
      id: 'mock_genui_${now.microsecondsSinceEpoch}',
      schemaVersion: 1,
      appVersion: 1,
      name: title,
      prompt: trimmed,
      surfaceJson: _surface(title, trimmed),
      runtimeData: const {},
      savedAt: now,
      updatedAt: now,
    );
  }

  String _titleFromPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('habit') || prompt.contains('习惯')) {
      return '习惯打卡';
    }
    if (lower.contains('countdown') || prompt.contains('倒计时')) {
      return '倒计时';
    }
    if (lower.contains('expense') || prompt.contains('记账')) {
      return '记账助手';
    }
    return '待办清单';
  }

  List<Map<String, Object?>> _surface(String title, String prompt) => [
    {
      'surfaceUpdate': {
        'surfaceId': 'surface_main',
        'components': [
          {
            'id': 'root',
            'component': {
              'Column': {
                'alignment': 'stretch',
                'children': {
                  'explicitList': ['title', 'summary', 'hint'],
                },
              },
            },
          },
          {
            'id': 'title',
            'component': {
              'Text': {
                'text': {'literalString': title},
                'usageHint': 'h3',
              },
            },
          },
          {
            'id': 'summary',
            'component': {
              'Text': {
                'text': {'literalString': '这是一个由 GenUI surface 渲染的小应用。'},
              },
            },
          },
          {
            'id': 'hint',
            'component': {
              'Text': {
                'text': {'literalString': '原始需求：$prompt'},
                'usageHint': 'caption',
              },
            },
          },
        ],
      },
    },
    {
      'beginRendering': {'surfaceId': 'surface_main', 'root': 'root'},
    },
  ];
}
