import 'dart:async';

typedef GetSyncDataCallback = FutureOr<String> Function(dynamic data);

enum MsgTypes { getSyncData }

abstract interface class PeerNet {
  GetSyncDataCallback? onGetSyncData;

  Future<void> start(int port);
}
