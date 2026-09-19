import 'package:json_annotation/json_annotation.dart';

part 'peer_data.g.dart';

@JsonSerializable()
class PeerData {
  final String ip;
  final int uptime;

  @JsonKey(name: "db_version")
  final int dbVersion;

  @JsonKey(name: "db_timestamp")
  final int dbTimestamp;

  @JsonKey(name: "db_hash")
  final String dbHash;

  @JsonKey(name: "snapshot_hash")
  final String snapshotHash;

  PeerData({
    required this.ip,
    required this.uptime,
    required this.dbVersion,
    required this.dbTimestamp,
    required this.dbHash,
    required this.snapshotHash,
  });

  factory PeerData.fromJson(Map<String, dynamic> json) =>
      _$PeerDataFromJson(json);

  Map<String, dynamic> toJson() => _$PeerDataToJson(this);
}
