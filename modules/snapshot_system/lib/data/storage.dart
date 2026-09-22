import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IStorage {
  Future<SharedPreferences> get prefs;

  Future<void> setLastSyncTimestamp(int timestamp);

  Future<int> getLastSyncTimestamp();

  Future<void> setDBHash(String hash);

  Future<String> getDBHash();

  Future<void> setSnapshotHash(String hash);

  Future<String> getSnapshotHash();

  Future<void> setStartTime(int timestamp);

  Future<int> getStartTime();
}

class Storage implements IStorage {
  final String _prefix = "snapshot";

  const Storage();

  @override
  Future<SharedPreferences> get prefs async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<void> setLastSyncTimestamp(int timestamp) async {
    (await prefs).setInt('${_prefix}_lastSyncTimestamp', timestamp);
  }

  @override
  Future<int> getLastSyncTimestamp() async {
    return (await prefs).getInt('${_prefix}_lastSyncTimestamp') ?? 0;
  }

  @override
  Future<void> setDBHash(String hash) async {
    (await prefs).setString('${_prefix}_db_hash', hash);
  }

  @override
  Future<String> getDBHash() async {
    return (await prefs).getString('${_prefix}_db_hash') ?? "";
  }

  @override
  Future<void> setSnapshotHash(String hash) async {
    (await prefs).setString('${_prefix}_snapshot_hash', hash);
  }

  @override
  Future<String> getSnapshotHash() async {
    return (await prefs).getString('${_prefix}_snapshot_hash') ?? "";
  }

  @override
  Future<void> setStartTime(int timestamp) async {
    (await prefs).setInt('${_prefix}_startTime', timestamp);
  }

  @override
  Future<int> getStartTime() async {
    return (await prefs).getInt('${_prefix}_startTime') ?? 0;
  }
}
