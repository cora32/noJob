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
  final ApplicationStatus total;
  final ApplicationStatus initialInterviews;
  final ApplicationStatus technicalInterviews;
  final ApplicationStatus rejected;
  final ApplicationStatus rejectedWithFeedback;
  final ApplicationStatus offers;

  ArcData({
    required this.total,
    required this.initialInterviews,
    required this.technicalInterviews,
    required this.rejected,
    required this.rejectedWithFeedback,
    required this.offers,
  });

  const ArcData.empty():
      total = ApplicationStatus.total,
      initialInterviews = ApplicationStatus.initialInterviews,
      technicalInterviews = ApplicationStatus.techInterviews,
      rejected = ApplicationStatus.rejected,
      rejectedWithFeedback = ApplicationStatus.rejectedWithFeedback,
      offers = ApplicationStatus.offer;
}

enum ApplicationStatus {
  total(count: 100, color: Color(0xFFA6A6A6)),
  // pending(size: 100, color: Color(0xFFFFCE93)),
  initialInterviews(count:  100, color: Color(0xFF19CCD2)),
  techInterviews(count:  100, color: Color(0xFF00FFB3)),
  rejected(count:  100, color: Color(0xFFED2727)),
  rejectedWithFeedback(count:  100, color: Color(0xFFDA5322)),
  offer(count:  100, color: Color(0xFF34D61D));

  final int count;
  final Color color;

  const ApplicationStatus({
    required this.count,
    required this.color,
  });
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState(arcData: ArcData.empty());

  void setText(ArcData arcData) {
    state = state.copyWith(arcData: arcData);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
