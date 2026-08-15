import 'package:NoJob/features/logs/presentation/providers/log_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchProvider = NotifierProvider<SearchNotifier, String>(
  SearchNotifier.new,
);

final filteredLogsProvider = Provider((ref) {
  final query = ref.watch(searchProvider).toLowerCase();
  final logsState = ref.watch(logsProvider);

  return logsState.whenData((state) {
    if (query.isEmpty) return state.logs;

    return state.logs.where((log) {
      final title = log.title.toLowerCase();
      final company = log.description.toLowerCase();
      return title.contains(query) || company.contains(query);
    }).toList();
  });
});
