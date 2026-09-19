import 'dart:async';

import 'package:peernet/server/domain/peer_data.dart';

typedef DataCallback = FutureOr<String> Function(dynamic data);
typedef VersionDataCallback = FutureOr<PeerData> Function(dynamic data);
typedef OnPeerFoundCallback = FutureOr<void> Function(PeerData peer);

sealed class ReplicationStrategy {}

class NoReplication extends ReplicationStrategy {}

class FullReplication extends ReplicationStrategy {}

class PartialFetch extends ReplicationStrategy {
  final int startFromTimestamp;

  PartialFetch(this.startFromTimestamp);
}

enum CommandMessages { peerHere }

enum MsgTypes { getSyncData, getVersionData }

abstract interface class IPeerNetComms {
  Future<String> getSyncData();

  Future<PeerData> getVersionData();

  Future<void> disconnect();
}

abstract interface class PeerNet {
  // FutureOr<int> Function()? getCount;
  // FutureOr<String> Function()? calculateHashForDB;

  Future<void> startServer(int peerNetPort, int discoveryPort);

  Future<void> discover(
    OnPeerFoundCallback callback, {
    int discoveryPort = 7835,
  });

  Future<IPeerNetComms> connect(String ip, {int port = 7834});

  Future<void> startListening();

  Future<void> fetchData();
}
