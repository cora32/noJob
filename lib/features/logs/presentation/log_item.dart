import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/domain/job_interface.dart';
import 'package:nojob/features/home/presentation/providers/home_provider.dart';
import 'package:nojob/features/logs/presentation/providers/log_provider.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/shared.dart';

class MobileLogItem extends StatelessWidget {
  final JobData item;

  const MobileLogItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SourceBox(item: item),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fullDateFormatDay.format(item.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          MobileStatusDropDown(item: item),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(width: 8),
                CloseButton(id: item.id ?? -1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LogItem extends StatelessWidget {
  final JobData item;

  const LogItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          item.id.toString(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w100,
            color: context.theme.textTheme.bodyMedium!.color!.withValues(
              alpha: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        DateWidget(date: item.date),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SourceBox(item: item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
      ],
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
            style: TextStyle(
              fontSize: 12,
              color: context.theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
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
        CloseButton(id: item.id ?? -1),
      ],
    );
  }
}

class CloseButton extends ConsumerWidget {
  final int id;

  const CloseButton({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.close, size: 16, color: Colors.red),
      padding: EdgeInsets.all(8.0),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Remove Record"),
            content: const Text("Are you sure you want to remove this record?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  if (id != -1) {
                    ref.read(logsProvider.notifier).removeJob(id);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Yes"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DateWidget extends StatelessWidget {
  final DateTime date;

  const DateWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          dateFormatDay.format(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        Text(
          dateFormatMY.format(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: context.theme.textTheme.bodyMedium!.color!.withValues(
              alpha: 0.8,
            ),
            height: 1.4,
          ),
        ),
        // Text(
        //   dateFormatTime.format(date),
        //   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w100, color: context.theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.6), height: 0.5),
        // ),
      ],
    );
  }
}

class SourceBox extends StatelessWidget {
  final JobData item;

  const SourceBox({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: SupportedSite.fromNameCode(item.source).color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          SupportedSite.fromNameCode(item.source).displayCode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MobileStatusDropDown extends ConsumerWidget {
  final JobData item;

  const MobileStatusDropDown({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        padding: EdgeInsetsGeometry.symmetric(vertical: 2, horizontal: 4),
        value: item.status.toLowerCase(),
        isDense: true,
        borderRadius: BorderRadius.circular(4),
        icon: const Icon(Icons.arrow_drop_down, size: 16),
        style: TextStyle(
          fontSize: 11,
          color: context.theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        onChanged: (String? newValue) {
          if (newValue != null && item.id != null) {
            ref.read(logsProvider.notifier).updateStatus(item.id!, newValue);
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
    );
  }
}
