import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/job_repo.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/shared/providers.dart';

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

class HomeViewModel extends AsyncNotifier<HomeState> {
  IJobRepo get _repo => ref.read(jobRepo);

  @override
  Future<HomeState> build() async {
    final totalJobsCount = await _repo.countTotal();
    final distinctTypes = await _repo.countDistinctTypes();

    if (totalJobsCount == 0) return const HomeState(arcDataList: []);

    final total = totalJobsCount.toDouble();
    final arcDataList = distinctTypes.map((item) {
      return ArcData(
        total: total,
        count: item.count.toDouble(),
        type: ApplicationType.fromNameCode(item.type),
      );
    }).toList();

    return HomeState(arcDataList: arcDataList);
  }
}
