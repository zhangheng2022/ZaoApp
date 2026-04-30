class RuntimeBridgeException implements Exception {
  const RuntimeBridgeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RuntimeBridgeHandler {
  RuntimeBridgeHandler({Map<String, Object?> initialData = const {}})
    : _runtimeData = Map<String, Object?>.from(initialData);

  static const allowedActions = {
    'runtime.get',
    'runtime.set',
    'runtime.patch',
    'toast.show',
  };

  final Map<String, Object?> _runtimeData;

  Map<String, Object?> get runtimeData => Map.unmodifiable(_runtimeData);

  Future<Object?> handle(String action, Map<String, Object?> payload) async {
    if (!allowedActions.contains(action)) {
      throw RuntimeBridgeException('Bridge action is not allowed: $action');
    }

    return switch (action) {
      'runtime.get' => _runtimeData[payload['key'] as String?],
      'runtime.set' => _set(payload),
      'runtime.patch' => _patch(payload),
      'toast.show' => null,
      _ => throw RuntimeBridgeException('Bridge action is not allowed: $action'),
    };
  }

  Object? _set(Map<String, Object?> payload) {
    final key = payload['key'] as String?;
    if (key == null || key.trim().isEmpty) {
      throw const RuntimeBridgeException('runtime.set requires a key.');
    }
    _runtimeData[key] = payload['value'];
    return null;
  }

  Object? _patch(Map<String, Object?> payload) {
    final value = payload['value'];
    if (value is! Map) {
      throw const RuntimeBridgeException('runtime.patch requires a map value.');
    }
    _runtimeData.addAll(Map<String, Object?>.from(value));
    return null;
  }
}
