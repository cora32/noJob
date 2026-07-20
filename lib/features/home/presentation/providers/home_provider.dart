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
  unknown(color: Color(0xFF000000)),
  initialInterviews(color: Color(0xFF19CCD2)),
  techInterviews(color: Color(0xFF0048FF)),
  rejected(color: Color(0xFFE80808)),
  rejectedDetailed(color: Color(0xFFF700FF)),
  offer( color: Color(0xFF34D61D));

  final Color color;

  const ApplicationType({required this.color});
}


class HomeNotifier extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    await Future.delayed(const Duration(seconds: 1));

    var dataList = _getDataList();

    return HomeState(arcDataList: dataList);
  }

  List<ArcData> _getDataList() {
    var rejections = ArcData(
        total: 500, count: 200, type: ApplicationType.rejected);
    var rejectionsDetailed = ArcData(
        total: 500, count: 100, type: ApplicationType.rejectedDetailed);
    var initialInterviews = ArcData(
        total: 500, count: 80, type: ApplicationType.initialInterviews);
    var techInterviews = ArcData(
        total: 500, count: 30, type: ApplicationType.techInterviews);
    var offers = ArcData(total: 500, count: 20, type: ApplicationType.offer);

    return [
      // total,
      rejections,
      rejectionsDetailed,
      initialInterviews,
      techInterviews,
      offers,
    ];
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
