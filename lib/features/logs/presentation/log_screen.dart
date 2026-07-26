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
        width: 450,
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

class AddJobDialog extends StatefulWidget {
  const AddJobDialog({super.key});

  @override
  State<AddJobDialog> createState() => _AddJobDialogState();
}

class _AddJobDialogState extends State<AddJobDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          title: const Text("Add Job Application"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Company Name"),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: "Job Link"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await ref
                      .read(logsProvider.notifier)
                      .addJob(
                        _nameController.text,
                        _descController.text,
                        _linkController.text,
                      );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(

                                fontSize: 12,
                                fontWeight: FontWeight.bold),
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
