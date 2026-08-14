import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LineChartState {
  final int applicationsToday;
  final Map<SupportedSite, List<FlSpot>> sourceData;

  LineChartState({required this.sourceData, required this.applicationsToday});

  LineChartState.empty() : sourceData = {}, applicationsToday = 0;
}

class LineChartNotifier extends AsyncNotifier<LineChartState> {
  @override
  Future<LineChartState> build() async {
    final repo = ref.watch(jobRepoProvider);
    final jobs = await repo.getData();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate total applications today across all sources
    int totalToday = 0;
    for (var job in jobs) {
      final jobDate = DateTime(job.date.year, job.date.month, job.date.day);
      if (jobDate == today) {
        totalToday++;
      }
    }

    final Map<SupportedSite, List<FlSpot>> sourceData = {};

    // Process each relevant source
    for (var source in SupportedSite.values) {
      if (source == SupportedSite.none) continue;

      final dataMap = <DateTime, int>{};
      // Initialize map with last 14 days for this source
      for (int i = 0; i < 14; i++) {
        final date = today.subtract(Duration(days: i));
        dataMap[date] = 0;
      }

      // Fill with real data for this source
      for (var job in jobs) {
        if (job.source == source.nameCode) {
          final jobDate = DateTime(job.date.year, job.date.month, job.date.day);
          if (dataMap.containsKey(jobDate)) {
            dataMap[jobDate] = dataMap[jobDate]! + 1;
          }
        }
      }

      // Convert to FlSpots, sorted by date (oldest to newest)
      final sortedDates = dataMap.keys.toList()..sort();
      final spots = <FlSpot>[];
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(FlSpot(i.toDouble(), dataMap[sortedDates[i]]!.toDouble()));
      }

      sourceData[source] = spots;
    }

    return LineChartState(
      sourceData: sourceData,
      applicationsToday: totalToday,
    );
  }
}

final lineChartProvider =
    AsyncNotifierProvider<LineChartNotifier, LineChartState>(
      LineChartNotifier.new,
    );
