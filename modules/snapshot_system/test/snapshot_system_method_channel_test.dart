import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapshot_system/snapshot_system_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSnapshotSystem platform = MethodChannelSnapshotSystem();
  const MethodChannel channel = MethodChannel('snapshot_system');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
