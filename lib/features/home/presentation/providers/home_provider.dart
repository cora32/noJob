import 'package:NoJob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final List<ArcData> arcDataList;

  const HomeState({required this.arcDataList});

  HomeState copyWith({List<ArcData>? arcDataList}) {
    return HomeState(arcDataList: arcDataList ?? List.empty());
  }
}

class RejectedData {
  final int defaultRejection;
  final int feedback;

  RejectedData({required this.defaultRejection, required this.feedback});
}

class ArcData {
  final int total;
  final int count;
  final ApplicationType type;

  const ArcData({
    required this.total,
    required this.count,
    required this.type,
  });

  ArcData.empty()
      : total = 0,
        count = 0,
        type = ApplicationType.unknown;
}

enum ApplicationType {
  unknown(color: Color(0xFF000000), nameCode: ""),
  initialInterviews(color: Color(0xFF19CCD2), nameCode: "initial"),
  techInterviews(color: Color(0xFF0048FF), nameCode: "tech_interview"),
  rejected(color: Color(0xFFE80808), nameCode: "rejected"),
  rejectedDetailed(color: Color(0xFFF700FF), nameCode: "rejected_detailed"),
  offer(color: Color(0xFF34D61D), nameCode: "offer");

  final Color color;
  final String nameCode;

  const ApplicationType({required this.color, required this.nameCode});

  static ApplicationType fromNameCode(String code) {
    return values.firstWhere(
          (e) => e.nameCode == code,
      orElse: () => ApplicationType.unknown,
    );
  }
}

class HomeNotifier extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final repo = ref.watch(jobRepoProvider);
    final jobs = await repo.getData();

    if (jobs.isEmpty) {
      return const HomeState(arcDataList: []);
    }

    final counts = <ApplicationType, int>{};
    for (var job in jobs) {
      final type = ApplicationType.fromNameCode(job.status);
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final total = jobs.length;
    final arcDataList = counts.entries.map((e) {
      return ArcData(
        total: total,
        count: e.value,
        type: e.key,
      );
    }).toList();

    return HomeState(arcDataList: arcDataList);
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

