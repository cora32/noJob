import 'dart:async';

import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';
import 'package:snapshot_system/data/storage.dart';

PeerNet getInstance({
  int snapshotVersion = 1,
  IStorage storage = const Storage(),
  required FutureOr<String> Function() calculateHashForDB,
  required FutureOr<int> Function() getDBCount,
}) => PeerNetStub.getInstance(
  snapshotVersion: 1,
  storage: const Storage(),
  calculateHashForDB: () async => "stub",
  getDBCount: () async => 0,
);

class PeerNetComms implements IPeerNetComms {
  PeerNetComms._();

  static final IPeerNetComms stub = PeerNetComms._();

  @override
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<String> getSyncData() {
    // TODO: implement getSyncData
    throw UnimplementedError();
  }

  @override
  Future<PeerData> getVersionData() {
    // TODO: implement getVersionData
    throw UnimplementedError();
  }
}

class PeerNetStub implements PeerNet {
  static final PeerNetStub _instance = PeerNetStub._();

  PeerNetStub._();

  factory PeerNetStub({required int snapshotVersion}) => _instance;

  factory PeerNetStub.getInstance({
    int snapshotVersion = 1,
    IStorage storage = const Storage(),
    required FutureOr<String> Function() calculateHashForDB,
    required FutureOr<int> Function() getDBCount,
  }) {
    return PeerNetStub._();
  }

  @override
  Future<void> discover(
    OnPeerFoundCallback callback, {
    int discoveryPort = 7835,
  }) async {
    // Noop for web target
  }

  @override
  Future<void> start(int peerNetPort, int discoveryPort) async {
    // Noop for web target
  }

  @override
  Future<IPeerNetComms> connect(String ip, {int port = 7834}) async {
    // Noop for web target

    return PeerNetComms.stub;
  }

  @override
  FutureOr<String> Function()? calculateHashForDB;

  @override
  FutureOr<int> Function()? getCount;

  @override
  Future<void> fetchData() {
    // TODO: implement fetchData
    throw UnimplementedError();
  }

  @override
  Future<void> startListening() {
    // TODO: implement startListening
    throw UnimplementedError();
  }

  @override
  Future<void> startServer(int peerNetPort, int discoveryPort) {
    // TODO: implement startServer
    throw UnimplementedError();
  }
}
