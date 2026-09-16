import 'package:logger/logger.dart';
import 'package:snapshot_system/data/db.dart';
import 'package:snapshot_system/data/log_entry.dart';


abstract class ISnapshotSystem implements ISnapshotAPI {
}

class SnapshotSystem extends ISnapshotSystem {
  final _logger = Logger(
    printer: PrettyPrinter(),
  );

  static SnapshotSystem? _instance;
  late final SnapshotAPI _api;

  SnapshotSystem._(int version) {
    _api = SnapshotAPI(version);
  }

  factory SnapshotSystem(int version) {
    _instance
    ?? = SnapshotSystem._(version);

    return _instance!;
  }

  @override
  Future<int> add(String data) async {
    _logger.i("[SnapshotSystem] Adding data: $data");
    final id = await _api.add(data);
    _logger.i("[SnapshotSystem] add result: $id");

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

    return id;
  }

  @override
  Future<int> remove(String hash) async {
    _logger.i("[SnapshotSystem] Removing hash: $hash");
    final id = await _api.remove(hash);
    _logger.i("[SnapshotSystem] Removed id: $id");

    return id;
  }

}