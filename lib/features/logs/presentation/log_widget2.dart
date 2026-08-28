import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/logs/presentation/log_item.dart';
import 'package:nojob/features/logs/presentation/log_screen.dart';
import 'package:nojob/features/logs/presentation/providers/log_provider.dart';
import 'package:nojob/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:nojob/shared/extensions.dart';

const int PREVIEW_LOGS_COUNT = 8;

class LogWidget2 extends ConsumerWidget {
  const LogWidget2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsProvider);

    return state.when(
      data: (state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Align(alignment: Alignment.centerRight, child: AddButton()),
            const SizedBox(height: 16),
            const Last8List(count: PREVIEW_LOGS_COUNT),
            const SizedBox(height: 8),
            if (state.logs.isNotEmpty && state.logs.length > PREVIEW_LOGS_COUNT)
              TextButton(
                onPressed: () {
                  ref
                      .read(navigationProvider.notifier)
                      .navigateTo(AppScreen.fullLog);
                },
                child: Text(context.res.fullLog),
              ),
          ],
        ),
      ),
      error: (err, stack) => Text(err.toString()),
      loading: () => const CircularProgressIndicator(),
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (context) => const AddJobDialog(),
        );
      },
      child: const Text(" + Add"),
    );
  }
}

class Last8List extends ConsumerWidget {
  final int count;

  const Last8List({super.key, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsProvider);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.theme.brightness == Brightness.dark
            ? Colors.black26
            : const Color(0xffefefef),
        borderRadius: BorderRadius.circular(12),
      ),
      child: state.when(
        data: (state) {
          final logs = state.logs;
          final last8Entries = logs
              .take(count)
              .toList(); // Do not reverse it because it is already reversed by the "order by DESC"

          if (last8Entries.isEmpty) {
            return SizedBox(
                height: 100,
                child: Center(child: Text(context.res.noLogs)));
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, entry) in last8Entries.indexed)
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    color: index % 2 == 0
                        ? Colors.transparent
                        : Colors.grey.withValues(alpha: 0.1),
                    child: context.isMobile
                        ? MobileLogItem(item: entry)
                        : LogItem(item: entry),
                  ),
              ],
            );
          }
        },
        error: (error, stackTrace) => Text(error.toString()),
        loading: () => const CircularProgressIndicator(),
      ),
    );
  }
}
