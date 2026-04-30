import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand assets and platform names are configured', () {
    expect(File('assets/images/logo.png').existsSync(), isTrue);
    expect(File('assets/images/launch_logo.png').existsSync(), isTrue);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/images/'));
    expect(pubspec, contains('flutter_native_splash:'));
    expect(pubspec, contains('image: assets/images/launch_logo.png'));
    expect(pubspec, contains('android_12:'));
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:label="ZaoApp"'),
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains('<string>ZaoApp</string>'),
    );
    expect(
      File('macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync(),
      contains('PRODUCT_NAME = ZaoApp'),
    );
    expect(
      File('windows/runner/Runner.rc').readAsStringSync(),
      contains('VALUE "ProductName", "ZaoApp"'),
    );
    expect(
      File('web/manifest.json').readAsStringSync(),
      contains('"name": "ZaoApp"'),
    );
  });
}
