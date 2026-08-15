import 'package:NoJob/features/home/domain/job_interface.dart';
import 'package:NoJob/features/logs/presentation/log_screen.dart';
import 'package:NoJob/features/logs/presentation/log_widget2.dart';
import 'package:NoJob/features/logs/presentation/providers/search_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FullLogScreen extends ConsumerWidget {
  const FullLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredLogsAsync = ref.watch(filteredLogsProvider);

    return Column(
      children: [
        const SizedBox(height: 16),
        const LogSearchBar(),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight,
          child: Padding(padding: EdgeInsetsGeometry.only(right: 24, top: 16),
              child: AddButton()),),
        Expanded(
          child: filteredLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Center(child: Text(context.res.noLogs));
              }

              return AnimatedListView<JobData>(
                items: logs,
                isSameItem: (item1, item2) => item1.id == item2.id,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                itemBuilder: (context, index) {
                  final item = logs[index];
                  return Container(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(left: 16),
                    color: index % 2 == 0
                        ? Colors.transparent
                        : Colors.grey.withValues(alpha: 0.1),
                    child: LogItem(item: item),
                  );
                },
                enterTransition: [
                  FadeIn(duration: const Duration(milliseconds: 300)),
                  SlideInUp(duration: const Duration(milliseconds: 300)),
                ],
                exitTransition: [
                  FadeIn(duration: const Duration(milliseconds: 300)),
                  SlideInDown(duration: const Duration(milliseconds: 300)),
                ],
                insertDuration: const Duration(milliseconds: 300),
                removeDuration: const Duration(milliseconds: 300),
              );
            },
            error: (error, stack) => Center(child: Text(error.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class LogSearchBar extends ConsumerStatefulWidget {
  const LogSearchBar({super.key});

  @override
  ConsumerState<LogSearchBar> createState() => _LogSearchBarState();
}

class _LogSearchBarState extends ConsumerState<LogSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(searchProvider.notifier).setQuery(value);
          setState(() {}); // Rebuild to show/hide the clear icon
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? Padding(
                  padding: EdgeInsetsGeometry.only(right: 16),
                  child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                      setState(() {});
                    },
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 20.0,
          ),
          hintText: context.res.search,
          filled: true,
          fillColor: context.theme.cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: context.appTheme.colorTheme.backgroundColor,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: context.appTheme.colorTheme.accentColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
