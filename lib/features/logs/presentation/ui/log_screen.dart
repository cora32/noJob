import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/logs/presentation/ui/log_item.dart';
import 'package:nojob/features/logs/presentation/ui/verification_webview.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/providers.dart';
import 'package:nojob/shared/scrapper/base_scrapper.dart';
import 'package:nojob/shared/shared.dart';

class LogWidget extends ConsumerWidget {
  final ScrapedVacancy? Function(String) fetchVacancy;
  final Function(String, String, String) addJob;

  const LogWidget({
    super.key,
    required this.fetchVacancy,
    required this.addJob,
  })@override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 550,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.res.logs, style: labelStyle),
              const SizedBox(height: 16),
              const Expanded(child: LogsPanel()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                        const AddJobDialog(
                          fetchVacancy: fetchVacancy,
                          addJob: addJob,
                        ),
                      );
                    },
                    child: Text(context.res.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddJobDialog extends ConsumerStatefulWidget {
  final ScrapedVacancy? Function(String) fetchVacancy;
  final Function(String, String, String) addJob;

  const AddJobDialog({super.key, this.fetchVacancy, this.addJob,});

  @override
  ConsumerState<AddJobDialog> createState() => _AddJobDialogState();
}

class _AddJobDialogState extends ConsumerState<AddJobDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isFetching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleFetch() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isFetching = true);

    final data = await widget.fetchVacancy(url);

    if (!mounted) return;

    if (data != null) {
      if (data.status == ScrapeStatus.verificationRequired) {
        final success = await showDialog<bool>(
          context: context,
          builder: (context) => VerificationDialog(url: url),
        );

        if (success == true) {
          // Retry fetching with new cookies
          return _handleFetch();
        }
      } else if (data.status == ScrapeStatus.success) {
        setState(() {
          if (data.companyName.isNotEmpty) {
            _nameController.text = data.companyName;
          }
          if (data.title.isNotEmpty) _descController.text = data.title;
        });
      } else {
        context.showErrorSnackBar(context.res.fetchError);
      }
    } else {
      context.showErrorSnackBar(context.res.fetchError);
    }

    setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.res;
    return AlertDialog(
      title: Text(l10n.addJob),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: l10n.link,
                suffixIcon: _isFetching
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.download),
                  onPressed: _handleFetch,
                  tooltip: context.res.fetch_details,
                ),
              ),
              onSubmitted: (_) => _handleFetch(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.company),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: l10n.description),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isFetching
              ? null
              : () async {
            if (_nameController.text.isNotEmpty) {
              await
              widget.addJob(
                _nameController.text,
                _descController.text,
                _linkController.text,
              );
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class LogsPanel extends ConsumerWidget {
  const LogsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsViewModel);

    void onRemove(int id) {
      ref.read(logsViewModel.notifier).onRemove(id);
    }

    void updateStatus(int? id, String? newStatus) {
      ref
          .read(logsViewModel.notifier)
          .updateStatus(id!, newStatus!);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.theme.brightness == Brightness.dark
            ? Colors.black26
            : const Color(0xffefefef),
        borderRadius: BorderRadius.circular(12),
      ),
      child: state.when(
        data: (state) {
          final logs = state.logs;

          if (logs.isEmpty) {
            return Center(child: Text(context.res.noLogs));
          } else {
            return ListView.builder(
              itemCount: logs.length,
              padding: EdgeInsetsGeometry.symmetric(
                vertical: 16.0,
                horizontal: 16,
              ),
              itemBuilder: (BuildContext context, int index) {
                final item = logs[index];

                return Container(
                  padding: EdgeInsetsGeometry.only(left: 16),
                  color: index % 2 == 0 ? Colors.transparent : Colors.grey[850],
                  child: context.isMobile
                      ? MobileLogItem(
                    item: item,
                    key: ValueKey(item.id),
                    onRemove: onRemove,
                    updateStatus: updateStatus,
                  )
                      : LogItem(
                    item: item,
                    key: ValueKey(item.id),
                    onRemove: onRemove,
                    updateStatus: updateStatus,
                  ),
                );
              },
            );
          }
        },
        error: (error, stackTrace) {
          return Text(error.toString());
        },
        loading: () {
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
