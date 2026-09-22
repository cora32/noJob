import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:snapshot_system/snapshot.dart';
import 'package:snapshot_system/snapshot_system_method_channel.dart';
import 'package:snapshot_system/snapshot_system_platform_interface.dart';

class MockSnapshotSystemPlatform
    with MockPlatformInterfaceMixin
    implements SnapshotSystemPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SnapshotSystemPlatform initialPlatform =
      SnapshotSystemPlatform.instance;

  test('$MethodChannelSnapshotSystem is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSnapshotSystem>());
  });

  test('getPlatformVersion', () async {
    SnapshotSystem snapshotSystemPlugin = SnapshotSystem();
    MockSnapshotSystemPlatform fakePlatform = MockSnapshotSystemPlatform();
    SnapshotSystemPlatform.instance = fakePlatform;

    expect(await snapshotSystemPlugin.getPlatformVersion(), '42');
  });
}
