import 'package:NoJob/features/home/data/database_service.dart';
import 'package:NoJob/features/home/domain/job_interface.dart';
import 'package:sqflite/sqflite.dart';

class JobRepo implements IJobRepo {
  final DatabaseService _databaseService;

  JobRepo(this._databaseService);

  @override
  Future<List<JobData>> getData() async {
    final db = await _databaseService.database;
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
    final db = await _databaseService.database;
    await db.insert(
      'jobs',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateJobStatus(int id, String status) async {
    final db = await _databaseService.database;
    await db.update(
      'jobs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteJob(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
