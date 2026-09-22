import 'dart:async';

import 'package:peernet/server/domain/peer_data.dart';

typedef DataCallback = FutureOr<String> Function(dynamic data);
typedef VersionDataCallback = FutureOr<PeerData> Function(dynamic data);
typedef OnPeerFoundCallback = FutureOr<void> Function(PeerData peer);

enum CommandMessages { PeerHere }

enum MsgTypes { GetInfo }

abstract interface class IPeerNetComms {
  Future<PeerData> getInfo();

  Future<void> disconnect();
}

abstract interface class PeerNet {
  Future<void> startServer(
    int peerNetPort,
    int discoveryPort, {
    required Future<String> Function() onGetDBHash,
    required Future<int> Function() onGetDBCount,
  })Stream<PeerData> discover({
    int discoveryPort = 7835,
  });

  // Future<IPeerNetComms> connect(String ip, {int port = 7834});

  Future<void> synchronizeDB();
}
