import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:snapshot_system/domain/log_entry.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ISnapshotAPI {
  Future<int> add(String data);

  Future<int> remove(String hash);

  Future<int> modify(String hash, String newData);

  Future<List<LogEntry>> getAll();

  Future<String> calculateHashForSnapshot();
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
    _logger.i("[SnapshotAPI] Initing db...");
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'snapshot.db');
    _logger.i("[SnapshotAPI] Snapshot path: $path; version: $_version");
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

  @override
  Future<String> calculateHashForSnapshot() async {
    final database = await db;
    // 1. Get the total row count to check if empty
    final countResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM Snapshot');
    final int totalRows = countResult.first['count'] as int? ?? 0;

    if (totalRows == 0) {
      return sha256.convert(utf8.encode("EMPTY_DATABASE")).toString();
    }

    // 2. Initialize the cryptographic chunk accumulator stream
    final output = AccumulatorSink<Digest>();
    final hashStream = sha256.startChunkedConversion(output);

    const int pageSize = 100; // Process 100 records at a time
    int offset = 0;

    // 3. Incrementally loop through the database using pages
    while (offset < totalRows) {
      // Fetch a single small page chunk, sorted deterministically by ID
      final List<Map<String, dynamic>> rows = await database.query(
        'Snapshot',
        orderBy: 'id ASC',
        // Deterministic ordering is mandatory for identical hashes
        limit: pageSize,
        offset: offset,
      );

      // If no more rows are returned unexpectedly, break out
      if (rows.isEmpty) break;

      // 4. Process the current page chunk row by row
      for (final row in rows) {
        final rowString =
            '${row['data']}|'
            '${row['timestamp']}|\n';

        // Push the row bytes straight into the active hash chunk accumulator
        hashStream.add(utf8.encode(rowString));
      }

      // 5. Shift the pointer window forward to the next page chunk
      offset += pageSize;
    }

    // 6. Close the accumulator stream to compute final fingerprint digest
    hashStream.close();

    // 7. Extract the aggregated hex string signature representation
    return output.events.single.toString();
  }
}
