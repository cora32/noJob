import 'package:NoJob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:NoJob/shared/extensions.dart';
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
  final double total;
  final double count;
  final ApplicationType type;

  const ArcData({required this.total, required this.count, required this.type});

  ArcData.empty() : total = 0.0, count = 0.0, type = ApplicationType.pending;
}

enum SupportedSite {
  hh(nameCode: "hh", displayCode: "HH", color: Color(0xFFFF0000)),
  linkedin(nameCode: "linkedin", displayCode: "IN", color: Color(0xFF0051FF)),
  indeed(nameCode: "indeed", displayCode: "ID", color: Color(0xFFD3FF35)),
  glassdoor(nameCode: "glassdoor", displayCode: "GD", color: Color(0xFF21B80E)),
  unknown(nameCode: "unknown", displayCode: "?", color: Color(0xFF454545)),
  none(nameCode: "none", displayCode: "", color: Color(0xFF000000));

  final Color color;
  final String nameCode;
  final String displayCode;

  const SupportedSite({
    required this.color,
    required this.nameCode,
    required this.displayCode,
  });

  static SupportedSite fromNameCode(String code) {
    return values.firstWhere(
      (e) => e.nameCode == code,
      orElse: () => SupportedSite.unknown,
    );
  }

  static SupportedSite fromLink(String link) {
    final lowerLink = link.toLowerCase();
    if (lowerLink.contains('hh.ru')) return SupportedSite.hh;
    if (lowerLink.contains('linkedin.com')) return SupportedSite.linkedin;
    if (lowerLink.contains('indeed.com')) return SupportedSite.indeed;
    if (lowerLink.contains('glassdoor.com')) return SupportedSite.glassdoor;
    return SupportedSite.unknown;
  }
}

enum ApplicationType {
  pending(color: Color(0xFF000000), nameCode: "pending"),
  initialInterviews(color: Color(0xFF19CCD2), nameCode: "first_interview"),
  techInterviews(color: Color(0xFF749CFF), nameCode: "tech_interview"),
  rejected(color: Color(0xFFE80808), nameCode: "rejected"),
  rejectedDetailed(color: Color(0xFFFFDD00), nameCode: "rejected_detailed"),
  offer(color: Color(0xFF34D61D), nameCode: "offer");

  final Color color;
  final String nameCode;

  const ApplicationType({required this.color, required this.nameCode});

  static ApplicationType fromNameCode(String code) {
    return values.firstWhere(
      (e) => e.nameCode == code,
      orElse: () => ApplicationType.pending,
    );
  }

  String localizedName(BuildContext context) {
    final l10n = context.res;
    return switch (this) {
      ApplicationType.pending => l10n.pending,
      ApplicationType.offer => l10n.offer,
      ApplicationType.rejected => l10n.rejected,
      ApplicationType.rejectedDetailed => l10n.rejected_detailed,
      ApplicationType.techInterviews => l10n.tech_interview,
      ApplicationType.initialInterviews => l10n.first_interview,
    };
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

    final total = jobs.length.toDouble();
    final arcDataList = counts.entries.map((e) {
      return ArcData(total: total, count: e.value.toDouble(), type: e.key);
    }).toList();

    return HomeState(arcDataList: arcDataList);
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
