import 'dart:async';

import 'package:logger/logger.dart';
import 'package:snapshot_system/data/snapshot_api.dart';
import 'package:snapshot_system/data/storage.dart';
import 'package:snapshot_system/domain/log_entry.dart';
import 'package:snapshot_system/domain/peer_data_hash.dart';

sealed class ReplicationStrategy {}

class NoReplication extends ReplicationStrategy {}

class FullReplication extends ReplicationStrategy {}

class PartialFetch extends ReplicationStrategy {
  final int startFromTimestamp;

  PartialFetch(this.startFromTimestamp);
}

abstract class ISnapshot implements ISnapshotAPI {
  Future<int> getLastSyncTimestamp();

  Future<String> getHashFromDB();

  Future<String> getHashFromSnapshot();

  Future<ReplicationStrategy> getReplicationStrategy(List<PeerDataHash> peers,);
}

class Snapshot extends ISnapshot {
  final _logger = Logger(
    printer: PrettyPrinter(),
  );

  final IStorage storage;
  static Snapshot? _instance;
  late final SnapshotAPI _api;
  Timer? _checkpointTimer;

  FutureOr<String> Function() onGetDBHash;
  FutureOr<int> Function() onGetDBCount;

  Snapshot._(int version,
      this.storage,
      this.onGetDBHash,
      this.onGetDBCount,) {
    _api = SnapshotAPI(version);
  }

  factory Snapshot(int version,
      IStorage storage,

      {
        required FutureOr<String> Function() onGetDBHash,
        required FutureOr<int> Function() onGetDBCount
      }) {
    _instance ??=
        Snapshot._(version, storage, onGetDBHash, onGetDBCount);

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

    final dbHash = await onGetDBHash();
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

  @override
  Future<ReplicationStrategy> getReplicationStrategy(
      List<PeerDataHash> peers,) async {
    final count = onGetDBCount();
    final isDbEmpty = count == 0;
    final todayMinus7 = DateTime
        .now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final lastSyncTimestamp = await getLastSyncTimestamp();
    final isTooOld = lastSyncTimestamp >= todayMinus7;
    final dbHash = await getHashFromDB();
    final snapshotHash = await getHashFromSnapshot();

    peers.sort((a, b) => b.uptime.compareTo(a.uptime));
    var isUpToDate = true;
    for (final peer in peers) {
      if (dbHash != peer.dbHash || snapshotHash != peer.snapshotHash) {
        isUpToDate = false;
        break;
      }
    }

    _logger.i("[PeerNet]: DB count: $count\n"
        " isDbEmpty: $isDbEmpty\n"
        " isTooOld: $isTooOld\n"
        " isUpToDate: $isUpToDate\n"
        " lastSyncTimestamp: $lastSyncTimestamp");

    if (isDbEmpty || isTooOld || lastSyncTimestamp == 0) {
      return FullReplication();
    } else if (isUpToDate) {
      return NoReplication();
    } else {
      return PartialFetch(lastSyncTimestamp);
    }
  }
}