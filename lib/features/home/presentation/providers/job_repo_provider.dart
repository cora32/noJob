import 'package:nojob/features/home/data/job_repo.dart';
import 'package:nojob/features/home/domain/job_interface.dart';
import 'package:nojob/features/home/presentation/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobRepoProvider = Provider<IJobRepo>((ref) {
  final databaseService = ref.watch(databaseProvider);
  return JobRepo(databaseService);
});
