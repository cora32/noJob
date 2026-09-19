import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;
  static String? _overridePath;

  static void setDatabasePath(String path) => _overridePath = dirname(path);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    bool useFfi = false;

    if (Platform.isWindows || Platform.isLinux) {
      useFfi = true;
    } else if (_overridePath != null) {
      // We are in a background isolate (like PeerNet server)
      useFfi = true;
    }

    final DatabaseFactory factory;
    if (useFfi) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }

    final dbPath = _overridePath ?? await factory.getDatabasesPath();

    // Ensure the directory exists (FFI doesn't create it automatically)
    await Directory(dbPath).create(recursive: true);

    final path = join(dbPath, 'nojob.db');
    return await openDatabaseWithFactory(path, factory);
  }

  static Future<Database> openDatabaseWithFactory(String path,
      DatabaseFactory factory) async {
    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: _onCreateInternal,
        onUpgrade: _onUpgradeInternal,
      ),
    );
  }

  static Future<Database> openDatabaseDirectly(String path) async {
    final DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux || _overridePath != null) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }

    return await openDatabaseWithFactory(path, factory);
  }

  static Future<void> _onUpgradeInternal(Database db, int oldVersion,
      int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE jobs ADD COLUMN link TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE jobs ADD COLUMN source TEXT NOT NULL DEFAULT "unknown"');
    }
    if (oldVersion < 4) {
      await db.execute('CREATE INDEX idx_jobs_title ON jobs(title)');
      await db.execute(
          'CREATE INDEX idx_jobs_description ON jobs(description)');
      await db.execute('CREATE INDEX idx_jobs_status ON jobs(status)');
    }
  }

  static Future<void> _onCreateInternal(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        link TEXT NOT NULL,
        status TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_jobs_title ON jobs(title)');
    await db.execute('CREATE INDEX idx_jobs_description ON jobs(description)');
    await db.execute('CREATE INDEX idx_jobs_status ON jobs(status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async =>
      _onUpgradeInternal(db, oldVersion, newVersion);

  Future<void> _onCreate(Database db, int version) async =>
      _onCreateInternal(db, version);


  Future<String> calculateFullDBHashPaged() async {
    final db = await database;

    // 1. Get the total row count to check if empty
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM jobs');
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
      final List<Map<String, dynamic>> rows = await db.query(
        'jobs',
        orderBy: 'id ASC',
        // Deterministic ordering is mandatory for identical hashes
        limit: pageSize,
        offset: offset,
      );

      // If no more rows are returned unexpectedly, break out
      if (rows.isEmpty) break;

      // 4. Process the current page chunk row by row
      for (final row in rows) {
        // Map the DB map to JobData temporarily to access fields cleanly
        final title = row['title'] as String;
        final description = row['description'] as String;
        final link = row['link'] as String;
        final status = row['status'] as String;
        final source = row['source'] as String;
        final date = DateTime.parse(row['date'] as String);


        final rowString = '$title|'
            '$description|'
            '$link|'
            '$status|'
            '$source|'
            '${date.toIso8601String()}|\n';

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
