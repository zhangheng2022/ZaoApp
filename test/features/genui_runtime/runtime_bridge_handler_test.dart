import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/genui_runtime/runtime_bridge_handler.dart';

void main() {
  test('allows runtime.get runtime.set runtime.patch and toast.show', () async {
    final bridge = RuntimeBridgeHandler(initialData: const {'count': 1});

    expect(await bridge.handle('runtime.get', const {'key': 'count'}), 1);
    await bridge.handle('runtime.set', const {'key': 'count', 'value': 2});
    await bridge.handle('runtime.patch', const {
      'value': {'title': 'demo'},
    });
    final toastResult = await bridge.handle('toast.show', const {
      'message': 'saved',
    });

    expect(bridge.runtimeData['count'], 2);
    expect(bridge.runtimeData['title'], 'demo');
    expect(toastResult, isNull);
  });

  test('rejects bridge actions outside the whitelist', () async {
    final bridge = RuntimeBridgeHandler();

    expect(
      () => bridge.handle('network.fetch', const {'url': 'https://example.com'}),
      throwsA(isA<RuntimeBridgeException>()),
    );
  });
}
