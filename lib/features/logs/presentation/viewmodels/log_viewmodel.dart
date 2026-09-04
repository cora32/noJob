import 'dart:async';

import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/features/logs/presentation/viewmodels/base_log_viewmodel.dart';
import 'package:nojob/shared/providers.dart';

class LogsState {
  final List<JobData> logs;

  LogsState({required this.logs});
}

class LogsViewModel extends BaseLogViewModel<LogsState> {
  late final scrapper = ref.read(scrapperRepo);

  @override
  Future<LogsState> build() async {
    final logs = await repo.getData();

    return LogsState(logs: logs);
  }
}
