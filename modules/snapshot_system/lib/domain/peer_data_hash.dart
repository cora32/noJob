import 'package:json_annotation/json_annotation.dart';

part 'peer_data_hash.g.dart';

@JsonSerializable()
class PeerDataHash {
  final String dbHash;
  final String snapshotHash;
  final int uptime;

  PeerDataHash({
    required this.dbHash,
    required this.snapshotHash,
    required this.uptime,
  });
}
