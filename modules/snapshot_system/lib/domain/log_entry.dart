import 'package:json_annotation/json_annotation.dart';

part 'log_entry.g.dart';

enum Operation { INSERT, REMOVE, MODIFY }

@JsonSerializable()
class LogEntry {
  final Operation operation;
  final String? hash;
  final String? data;

  LogEntry({required this.operation, required this.hash, required this.data});

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LogEntryToJson(this);
}
