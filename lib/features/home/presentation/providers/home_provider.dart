import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final ArcData arcData;

  const HomeState({required this.arcData});

  HomeState copyWith({ArcData? arcData}) {
    return HomeState(arcData: arcData ?? this.arcData);
  }
}

class RejectedData {
  final int defaultRejection;
  final int feedback;

  RejectedData({required this.defaultRejection, required this.feedback});
}

class ArcData {
  final ApplicationData total;
  final ApplicationData initialInterviews;
  final ApplicationData technicalInterviews;
  final ApplicationData rejected;
  final ApplicationData rejectedWithFeedback;
  final ApplicationData offers;

  const ArcData({
    required this.total,
    required this.initialInterviews,
    required this.technicalInterviews,
    required this.rejected,
    required this.rejectedWithFeedback,
    required this.offers,
  });

  ArcData.empty()
    : total = ApplicationData.empty(),
      initialInterviews = ApplicationData.empty(),
      technicalInterviews = ApplicationData.empty(),
      rejected = ApplicationData.empty(),
      rejectedWithFeedback = ApplicationData.empty(),
      offers = ApplicationData.empty();
}

class ApplicationData{
  final ApplicationStatus status;
  final int count;

  ApplicationData({required this.status, required this.count});

  const ApplicationData.empty() :
      status = ApplicationStatus.total,
      count = 0;
}

enum ApplicationStatus {
  total(color: Color(0xFFA6A6A6)),
  // pending(size: 100, color: Color(0xFFFFCE93)),
  initialInterviews(color: Color(0xFF19CCD2)),
  techInterviews(color: Color(0xFF0048FF)),
  rejected(color: Color(0xFFED2727)),
  rejectedWithFeedback(color: Color(0xFFDA5322)),
  offer( color: Color(0xFF34D61D));

  final Color color;

  const ApplicationStatus({required this.color});
}


class HomeNotifier extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    await Future.delayed(const Duration(seconds: 1));

    return HomeState(arcData: ArcData(
      total: ApplicationData(status: ApplicationStatus.total, count: 400),
      initialInterviews: ApplicationData(status: ApplicationStatus.initialInterviews, count: 40),
      technicalInterviews: ApplicationData(status: ApplicationStatus.techInterviews, count: 20),
      rejected: ApplicationData(status: ApplicationStatus.rejected, count: 80),
      rejectedWithFeedback: ApplicationData(status: ApplicationStatus.rejectedWithFeedback, count: 12),
      offers: ApplicationData(status: ApplicationStatus.offer, count: 50),
    ));
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
