import 'package:flutter/widgets.dart';

class MiniAppRendererRegistry {
  const MiniAppRendererRegistry();

  static const Set<String> supportedTypes = {
    'todo_list',
    'habit_tracker',
    'countdown',
    'expense_tracker',
  };

  bool supports(String? type) => supportedTypes.contains(type);

  Widget build(BuildContext context, Map<String, Object?> config) {
    final type = config['type'] as String?;
    if (!supports(type)) {
      return const Center(child: Text('Unsupported mini app configuration'));
    }

    return _NamedMiniAppRenderer(type: type!, config: config);
  }
}

class _NamedMiniAppRenderer extends StatelessWidget {
  _NamedMiniAppRenderer({required this.type, required this.config})
    : super(key: ValueKey('${type}_renderer'));

  final String type;
  final Map<String, Object?> config;

  @override
  Widget build(BuildContext context) {
    final name = config['name'] as String? ?? 'Untitled mini app';

    return Center(child: Text(name));
  }
}
