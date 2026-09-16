import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:snapshot_system/data/log_entry.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ISnapshotAPI {
  Future<int> add(String data);

  Future<int> remove(String hash);

  Future<int> modify(String hash, String newData);

  Future<List<LogEntry>> getAll();
}

class SnapshotAPI extends ISnapshotAPI {
  final _logger = Logger(printer: PrettyPrinter());
  static SnapshotAPI? _instance;
  final int _version;

  SnapshotAPI._(this._version);

  Database? _db;

  factory SnapshotAPI(int version) {
    _instance ??= SnapshotAPI._(version);

    return _instance!;
  }

  Future<Database> get db async {
    _logger.i("[SnapshotAPI] initing db...");
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'snapshot.db');
    _logger.i("[SnapshotAPI] Path path: $path; version: $_version");
    _db ??= await openDatabase(
      path,
      version: _version,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE Snapshot (id INTEGER PRIMARY KEY, data TEXT NOT NULL, timestamp INTEGER NOT NULL)',
        );
      },
    );

    return _db!;
  }

  Future<int> _addEntry(String entry) async {
    _logger.i("[SnapshotDB] _addEntry: $entry");

    final result = (await db).transaction((txn) async {
      return await txn.rawInsert(
        'INSERT INTO Snapshot (data, timestamp) VALUES (?, ?)',
        [entry, DateTime.now().millisecondsSinceEpoch],
      );
    });

    _logger.i("[SnapshotDB] _addEntry result: $result");
    if (result == null) {
      throw Exception('Transaction failed');
    }

    return result;
  }

  @override
  Future<int> add(String data) async {
    final entry = '${Operation.INSERT.name};$data';
    return _addEntry(entry);
  }

  @override
  Future<int> modify(String hash, String newData) async {
    final entry = '${Operation.MODIFY.name};$hash;$newData';
    return _addEntry(entry);
  }

  @override
  Future<int> remove(String hash) async {
    final entry = '${Operation.REMOVE.name};$hash';
    return _addEntry(entry);
  }

  @override
  Future<List<LogEntry>> getAll() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.rawQuery(
      'SELECT * FROM Snapshot',
    );

    return List.generate(maps.length, (i) {
      final row = maps[i];
      final String rawData = row['data'] as String;

      // Parse the semi-colon separated entry text stored via add/modify/remove
      final parts = rawData.split(';');
      final opName = parts[0];
      final Operation op = Operation.values.firstWhere(
        (e) => e.name == opName,
        orElse: () => Operation.INSERT,
      );

      String? hash;
      String? data;

      if (op == Operation.INSERT) {
        data = parts.sublist(1).join(';');
      } else if (op == Operation.REMOVE) {
        hash = parts.length > 1 ? parts[1] : null;
      } else if (op == Operation.MODIFY) {
        hash = parts.length > 1 ? parts[1] : null;
        data = parts.length > 2 ? parts.sublist(2).join(';') : null;
      }

      return LogEntry(operation: op, hash: hash, data: data);
    });
  }
}
