import 'dart:async';

import 'package:logger/logger.dart';
import 'package:snapshot_system/data/snapshot_api.dart';
import 'package:snapshot_system/data/storage.dart';
import 'package:snapshot_system/domain/log_entry.dart';


abstract class ISnapshotSystem implements ISnapshotAPI {
  late FutureOr<String> Function() calculateHashForDB;
  late FutureOr<int> Function() getDBCount;

  Future<int> getLastSyncTimestamp();

  Future<String> getHashFromDB();

  Future<String> getHashFromSnapshot();
}

class SnapshotSystem extends ISnapshotSystem {
  final _logger = Logger(
    printer: PrettyPrinter(),
  );

  final IStorage storage;
  static SnapshotSystem? _instance;
  late final SnapshotAPI _api;
  Timer? _checkpointTimer;

  @override
  FutureOr<String> Function() calculateHashForDB;
  @override
  FutureOr<int> Function() getDBCount;

  SnapshotSystem._(int version,
      this.storage,
      this.calculateHashForDB,
      this.getDBCount,) {
    _api = SnapshotAPI(version);
  }

  factory SnapshotSystem(int version,
      IStorage storage,
      FutureOr<String> Function() calculateHashForDB,
      FutureOr<int> Function() getDBCount) {
    _instance ??=
        SnapshotSystem._(version, storage, calculateHashForDB, getDBCount);

    return _instance!;
  }

  @override
  Future<int> add(String data) async {
    _logger.i("[SnapshotSystem] Adding data: $data");
    final id = await _api.add(data);
    _logger.i("[SnapshotSystem] add result: $id");

    _triggerCheckpoint();

    return id;
  }

  @override
  Future<List<LogEntry>> getAll() async {
    _logger.i('[SnapshotSystem] Fetching all data...');
    final result = await _api.getAll();

    _logger.i(
        "[SnapshotSystem] Returning ${result.length}; Last 2: ${result.reversed
            .take(2)}");

    return result;
  }

  @override
  Future<int> modify(String hash, String newData) async {
    _logger.i("[SnapshotSystem] Modifying hash: $hash; newData: $newData");
    final id = await _api.modify(hash, newData);
    _logger.i("[SnapshotSystem] Mod result: $id");

    _triggerCheckpoint();

    return id;
  }

  @override
  Future<int> remove(String hash) async {
    _logger.i("[SnapshotSystem] Removing hash: $hash");
    final id = await _api.remove(hash);
    _logger.i("[SnapshotSystem] Removed id: $id");

    _triggerCheckpoint();

    return id;
  }

  void _triggerCheckpoint() {
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer(const Duration(seconds: 2), () async {
      await _checkpoint();
    });
  }

  Future<void> _checkpoint() async {
    _logger.i("[SnapshotSystem] Checkpoint");

    final dbHash = await calculateHashForDB();
    final snapshotHash = await _api.calculateHashForSnapshot();
    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;

    await storage.setDBHash(dbHash);
    await storage.setSnapshotHash(snapshotHash);
    await storage.setLastSyncTimestamp(timestamp);

    _logger.i(
        "[SnapshotSystem] DB hash: $dbHash\n Snapshot hash: $snapshotHash\n timestamp: $timestamp");
  }

  @override
  Future<int> getLastSyncTimestamp() async {
    final timestamp = await storage.getLastSyncTimestamp();
    _logger.i("[SnapshotSystem] Last sync timestamp: $timestamp");

    return timestamp;
  }

  @override
  Future<String> getHashFromDB() async {
    final hash = await storage.getDBHash();
    _logger.i("[SnapshotSystem] DB hash: $hash");

    return hash;
  }

  @override
  Future<String> getHashFromSnapshot() async {
    final hash = await storage.getSnapshotHash();
    _logger.i("[SnapshotSystem] Snapshot hash: $hash");

    return hash;
  }

  @override
  Future<String> calculateHashForSnapshot() => _api.calculateHashForSnapshot();
}