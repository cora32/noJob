import 'package:NoJob/features/logs/presentation/log_screen.dart';
import 'package:NoJob/features/logs/presentation/providers/log_provider.dart';
import 'package:NoJob/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogWidget2 extends ConsumerWidget {
  const LogWidget2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsProvider);

    return state.when(
      data: (state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: AddButton(),
            ),
            const SizedBox(height: 16),
            const Last8List(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).navigateTo(
                    AppScreen.fullLog);
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
  const Last8List({super.key});

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
          final last8Entries = logs.take(5).toList();

          if (last8Entries.isEmpty) {
            return Center(child: Text(context.res.noLogs));
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
                    child: LogItem(item: entry),
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
