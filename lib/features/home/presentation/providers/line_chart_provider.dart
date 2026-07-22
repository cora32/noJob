import 'package:NoJob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LineChartState {
  final int applicationsToday;
  final List<FlSpot> data;

  LineChartState({required this.data, required this.applicationsToday});

  LineChartState.empty() : data = [], applicationsToday = 0;
}

class LineChartNotifier extends AsyncNotifier<LineChartState> {
  @override
  Future<LineChartState> build() async {
    final repo = ref.watch(jobRepoProvider);
    final jobs = await repo.getData();

    // Group jobs by date for the last 14 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dataMap = <DateTime, int>{};

    // Initialize map with last 14 days
    for (int i = 0; i < 14; i++) {
      final date = today.subtract(Duration(days: i));
      dataMap[date] = 0;
    }

    // Fill with real data
    for (var job in jobs) {
      final jobDate = DateTime(job.date.year, job.date.month, job.date.day);
      if (dataMap.containsKey(jobDate)) {
        dataMap[jobDate] = dataMap[jobDate]! + 1;
      }
    }

    // Convert to FlSpots, sorted by date (oldest to newest)
    final sortedDates = dataMap.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataMap[sortedDates[i]]!.toDouble()));
    }

    return LineChartState(data: spots, applicationsToday: dataMap[today] ?? 0);
  }
}

final lineChartProvider =
    AsyncNotifierProvider<LineChartNotifier, LineChartState>(
      LineChartNotifier.new,
    );
