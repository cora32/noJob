import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final dbProvider = Provider((ref) => DatabaseService());

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
        version: 3,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async =>
      _onUpgradeInternal(db, oldVersion, newVersion);

  Future<void> _onCreate(Database db, int version) async =>
      _onCreateInternal(db, version);
}
