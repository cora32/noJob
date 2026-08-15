import 'package:NoJob/features/logs/presentation/log_screen.dart';
import 'package:NoJob/features/logs/presentation/providers/log_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FullLogScreen extends ConsumerWidget {
  const FullLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsProvider);

    return state.when(
      data: (logsState) {
        final logs = logsState.logs;

        if (logs.isEmpty) {
          return Center(child: Text(context.res.noLogs));
        }

        return ListView.builder(
          itemCount: logs.length,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          itemBuilder: (context, index) {
            final item = logs[index];
            return Container(
              padding: const EdgeInsets.only(left: 16),
              color: index % 2 == 0
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.1),
              child: LogItem(item: item),
            );
          },
        );
      },
      error: (error, stack) => Center(child: Text(error.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
