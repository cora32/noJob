import 'package:nojob/features/logs/presentation/viewmodels/base_log_viewmodel.dart';
import 'package:nojob/features/logs/presentation/viewmodels/log_viewmodel.dart';

class SearchViewModel extends BaseLogViewModel<LogsState> {
  String _query = '';

  @override
  Future<LogsState> build() async {
    final filteredList = await repo.searchLogs(_query);

    return LogsState(logs: filteredList);
  }

  void setQuery(String query) {
    _query = query;

    ref.invalidateSelf();
  }

  void clear() {
    _query = '';

    ref.invalidateSelf();
  }
}
