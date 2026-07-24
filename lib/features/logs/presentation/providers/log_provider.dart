import 'dart:async';

import 'package:NoJob/features/home/domain/job_interface.dart';
import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:NoJob/features/home/presentation/providers/line_chart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsState {
  final List<JobData> logs;

  LogsState({required this.logs});
}

class LogsNotifier extends AsyncNotifier<LogsState> {
  @override
  Future<LogsState> build() async {
    final repo = ref.watch(jobRepoProvider);
    final logs = await repo.getData();

    return LogsState(logs: logs);
  }

  Future<void> addJob(String title, String description, String link) async {
    final jobData = JobData(
      date: DateTime.now(),
      title: title,
      description: description,
      link: link,
      status: ApplicationType.pending.nameCode,
    );

    final repo = ref.read(jobRepoProvider);
    await repo.addJob(jobData);

    ref.invalidateSelf();
    ref.invalidate(lineChartProvider);
    ref.invalidate(homeProvider);
  }

  Future<void> updateStatus(int id, String status) async {
    final repo = ref.read(jobRepoProvider);
    await repo.updateJobStatus(id, status);

    ref.invalidateSelf();
    ref.invalidate(lineChartProvider);
    ref.invalidate(homeProvider);
  }

  Future<void> removeJob(int id) async {
    final repo = ref.read(jobRepoProvider);
    await repo.deleteJob(id);

    ref.invalidateSelf();
    ref.invalidate(lineChartProvider);
    ref.invalidate(homeProvider);
  }
}

final logsProvider = AsyncNotifierProvider<LogsNotifier, LogsState>(
  LogsNotifier.new,
);
