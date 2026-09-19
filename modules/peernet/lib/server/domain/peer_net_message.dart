import 'package:json_annotation/json_annotation.dart';
import 'package:peernet/server/domain/i_peernet.dart';

part 'peer_net_message.g.dart';

@JsonSerializable()
class PeerNetMessage {
  final CommandMessages message;
  final String json;

  PeerNetMessage({required this.message, required this.json});

  factory PeerNetMessage.fromJson(Map<String, dynamic> json) =>
      _$PeerNetMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PeerNetMessageToJson(this);
}
