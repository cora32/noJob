import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/job_repo.dart';
import 'package:nojob/features/home/domain/job_interface.dart';

final jobRepoProvider = Provider<IJobRepo>((ref) {
  return JobRepo(ref);
});
