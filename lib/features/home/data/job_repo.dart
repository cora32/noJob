import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/features/home/domain/job_interface.dart';
import 'package:sqflite/sqflite.dart';

class JobRepo implements IJobRepo {
  final Ref _ref;

  JobRepo(this._ref);

  @override
  Future<List<JobData>> getData() async {
    final db = await _ref
        .read(dbProvider)
        .database;
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
    final db = await _ref
        .read(dbProvider)
        .database;
    await db.insert(
      'jobs',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateJobStatus(int id, String status) async {
    final db = await _ref
        .read(dbProvider)
        .database;
    await db.update(
      'jobs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteJob(int id) async {
    final db = await _ref
        .read(dbProvider)
        .database;
    await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> getLastTimestamp() async {
    final db = await _ref
        .read(dbProvider)
        .database;
    final result =
    await db.rawQuery('SELECT MAX(date) as last_date FROM jobs');
    final lastDateStr = result.first['last_date'] as String?;
    return lastDateStr != null
        ? DateTime
        .parse(lastDateStr)
        .millisecondsSinceEpoch
        : 0;
  }
}
