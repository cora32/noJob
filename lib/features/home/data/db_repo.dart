import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/shared/providers.dart';
import 'package:sqflite/sqflite.dart';

class DBRepo implements IDBRepo {
  final Ref _ref;

  DBRepo(this._ref);

  Future<Database> get _db => _ref.read(dbService).database;

  @override
  Future<List<JobData>> getData() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'jobs',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JobData.fromMap(maps[i]);
    });
  }

  @override
  Future<void> addJob(JobData data) async {
    final db = await _db;
    await db.insert(
      'jobs',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateJobStatus(int id, String status) async {
    final db = await _db;
    await db.update(
      'jobs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteJob(int id) async {
    final db = await _db;
    await db.delete('jobs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getLastTimestamp() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT MAX(date) as last_date FROM jobs');
    final lastDateStr = result.first['last_date'] as String?;
    return lastDateStr != null
        ? DateTime.parse(lastDateStr).millisecondsSinceEpoch
        : 0;
  }

  @override
  Future<List<CountResult>> countDistinctTypes() async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM jobs GROUP BY status',
    );

    return results.map((row) {
      return CountResult(
        type: row['status'] as String,
        count: row['count'] as int,
      );
    }).toList();
  }

  @override
  Future<int> countTotal() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM jobs');
    return result.first['count'] as int;
  }

  @override
  Future<List<JobData>> searchLogs(String query) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'jobs',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return JobData.fromMap(maps[i]);
    });
  }
}
