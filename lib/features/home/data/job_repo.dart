import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/providers.dart';

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

class JobRepo implements IJobRepo {
  final Ref _ref;
  late final IDBRepo repo = _ref.read(dbRepo);

  JobRepo(this._ref);

  @override
  Future<void> addJob(String title, String description, String link) async {
    final jobData = JobData(
      date: DateTime.now(),
      title: title,
      description: description,
      link: link,
      status: ApplicationType.pending.nameCode,
      source: SupportedSite.fromLink(link).nameCode,
    );

    await repo.addJob(jobData);
  }

  @override
  Future<List<CountResult>> countDistinctTypes() async {
    return await repo.countDistinctTypes();
  }

  @override
  Future<int> countTotal() async {
    return await repo.countTotal();
  }

  @override
  Future<void> deleteJob(int id) async {
    return await repo.deleteJob(id);
  }

  @override
  Future<List<JobData>> getData() async {
    return await repo.getData();
  }

  @override
  Future<int> getLastTimestamp() async {
    return await repo.getLastTimestamp();
  }

  @override
  Future<void> updateJobStatus(int id, String status) async {
    return await repo.updateJobStatus(id, status);
  }

  @override
  Future<List<JobData>> searchLogs(String query) async {
    return repo.searchLogs(query);
  }
}
