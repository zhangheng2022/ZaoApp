import 'config_generation_service.dart';

class MockConfigGenerationService implements ConfigGenerationService {
  const MockConfigGenerationService();

  @override
  Future<Map<String, Object?>> generate(String description) async {
    final normalized = description.toLowerCase();

    if (_containsAny(normalized, const ['习惯', '打卡', 'habit'])) {
      return _baseConfig(
        id: 'habit_mock',
        name: '习惯打卡',
        type: 'habit_tracker',
        fields: const [
          {'key': 'title', 'label': '习惯名称', 'type': 'text'},
          {'key': 'done', 'label': '今日完成', 'type': 'switch'},
        ],
      );
    }

    if (_containsAny(normalized, const ['倒计时', 'countdown', 'deadline'])) {
      return _baseConfig(
        id: 'countdown_mock',
        name: '倒计时',
        type: 'countdown',
        fields: const [
          {'key': 'title', 'label': '目标名称', 'type': 'text'},
          {'key': 'targetDate', 'label': '目标日期', 'type': 'date'},
        ],
      );
    }

    if (_containsAny(normalized, const ['记账', 'expense', 'money'])) {
      return _baseConfig(
        id: 'expense_mock',
        name: '记账',
        type: 'expense_tracker',
        fields: const [
          {'key': 'title', 'label': '项目', 'type': 'text'},
          {'key': 'amount', 'label': '金额', 'type': 'number'},
        ],
      );
    }

    return _baseConfig(
      id: 'todo_mock',
      name: '待办清单',
      type: 'todo_list',
      fields: const [
        {'key': 'title', 'label': '任务', 'type': 'text'},
        {'key': 'done', 'label': '完成', 'type': 'switch'},
      ],
    );
  }

  bool _containsAny(String source, List<String> keywords) =>
      keywords.any(source.contains);

  Map<String, Object?> _baseConfig({
    required String id,
    required String name,
    required String type,
    required List<Map<String, Object?>> fields,
  }) => {
    'id': id,
    'schemaVersion': 1,
    'appVersion': 1,
    'name': name,
    'type': type,
    'fields': fields,
  };
}
