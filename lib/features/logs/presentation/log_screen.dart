import 'package:NoJob/features/home/domain/job_interface.dart';
import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/logs/presentation/providers/log_provider.dart';
import 'package:NoJob/l10n/app_localizations.dart';
import 'package:NoJob/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogWidget extends ConsumerWidget {
  const LogWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(logsProvider);

    return Card(
      elevation: 4,
      color: Colors.white,
      child: SizedBox(
        width: 550,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.logs, style: labelStyle),
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
                        builder: (context) => const AddJobDialog(),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.add),
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
  const AddJobDialog({super.key});

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

    final data = await ref.read(logsProvider.notifier).fetchVacancy(url);

    if (!mounted) return;

    if (data != null) {
      setState(() {
        if (data.companyName.isNotEmpty)
          _nameController.text = data.companyName;
        if (data.title.isNotEmpty) _descController.text = data.title;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fetchError),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
    }

    setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(l10n.addJob),
      content: Column(
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
                tooltip: AppLocalizations.of(context)!.fetch_details,
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
              await ref.read(logsProvider.notifier).addJob(
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
    final state = ref.watch(logsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xffefefef),
        borderRadius: BorderRadius.circular(12),
      ),
      child: state.when(
        data: (state) {
          final logs = state.logs;

          if (logs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noLogs));
          } else {
            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (BuildContext context, int index) {
                final item = logs[index];

                return LogItem(item: item, key: ValueKey(item.id));
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

class LogItem extends StatelessWidget {
  final JobData item;

  const LogItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            item.id.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w100),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ApplicationSource
                            .fromNameCode(item.source)
                            .color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          ApplicationSource
                              .fromNameCode(item.source)
                              .displayCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StateToggle(item: item),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StateToggle extends ConsumerWidget {
  final JobData item;

  const StateToggle({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            padding: EdgeInsetsGeometry.symmetric(vertical: 2, horizontal: 4),
            value: item.status.toLowerCase(),
            isDense: true,
            borderRadius: BorderRadius.circular(4),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            onChanged: (String? newValue) {
              if (newValue != null && item.id != null) {
                ref
                    .read(logsProvider.notifier)
                    .updateStatus(item.id!, newValue);
              }
            },
            items: ApplicationType.values.map((ApplicationType type) {
              return DropdownMenuItem<String>(
                value: type.nameCode,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: type.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(type.localizedName(context)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.red),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    title: const Text("Remove Record"),
                    content: const Text(
                      "Are you sure you want to remove this record?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("No"),
                      ),
                      TextButton(
                        onPressed: () {
                          if (item.id != null) {
                            ref.read(logsProvider.notifier).removeJob(item.id!);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text("Yes"),
                  ),
                    ],
                  ),
            );
          },
        ),
      ],
    );
  }
}
