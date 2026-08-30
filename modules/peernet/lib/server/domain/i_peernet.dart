import 'dart:async';

import 'package:peernet/server/domain/transfer.dart';

typedef DataCallback = FutureOr<String> Function(dynamic data);
typedef VersionDataCallback = FutureOr<VersionData> Function(dynamic data);
typedef OnPeerFoundCallback = FutureOr<void> Function(PeerData peer);

enum MsgTypes { getSyncData, getVersionData }

abstract interface class IPeerNetComms {
  Future<String> getSyncData();

  Future<VersionData> getVersionData();

  Future<void> disconnect();
}

abstract interface class PeerNet {
  DataCallback? onGetSyncData;
  VersionDataCallback? onGetVersion;

  Future<void> start(int peerNetPort, int discoveryPort);

  Future<void> discover(
    OnPeerFoundCallback callback, {
    int discoveryPort = 7835,
  });

  Future<IPeerNetComms> connect(String ip, {int port = 7834});
}
