import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/features/logs/presentation/ui/log_item.dart';
import 'package:nojob/features/logs/presentation/ui/log_widget2.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/providers.dart';

class FullLogScreen extends ConsumerWidget {
  const FullLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(searchViewModel);

    void onRemove(int id) {
      ref.read(searchViewModel.notifier).onRemove(id);
    }

    void updateStatus(int? id, String? newStatus) {
      ref
          .read(searchViewModel.notifier)
          .updateStatus(id!, newStatus!);
    }

    void onSave(String link, String title, String description) {
      ref
          .read(searchViewModel.notifier)
          .addJob(title, description, link);
    }

    void fetchVacancy(String link) {
      ref
          .read(searchViewModel.notifier)
          .fetchVacancy(link);
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const LogSearchBar(),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight,
          child: Padding(padding: EdgeInsetsGeometry.only(right: 24, top: 16),
            child: AddButton(addJob: onSave, fetchVacancy: fetchVacancy),)),
        Expanded(
          child: viewModel.when(
            data: (state) {
              if (state.logs.isEmpty) {
                return Center(child: Text(context.res.noLogs));
              }

              return AnimatedListView<JobData>(
                items: state.logs,
                isSameItem: (item1, item2) => item1.id == item2.id,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                itemBuilder: (context, index) {
                  final item = state.logs[index];
                  return Container(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(left: 16),
                    color: index % 2 == 0
                        ? Colors.transparent
                        : Colors.grey.withValues(alpha: 0.1),
                    child: context.isMobile
                        ? MobileLogItem(item: item,
                        onRemove: onRemove,
                        updateStatus: updateStatus)
                        : LogItem(item: item,
                        onRemove: onRemove,
                        updateStatus: updateStatus),
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
          ref.read(searchViewModel.notifier).setQuery(value);
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
                      ref.read(searchViewModel.notifier).clear();
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
