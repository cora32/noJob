import 'dart:async';

import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';
import 'package:snapshot_system/data/storage.dart';

PeerNet getInstance({
  IStorage storage = const Storage(),
}) => PeerNetStub.getInstance(
  storage: const Storage(),
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
  }) {
    return PeerNetStub._();
  }

  @override
  Stream<PeerData> discover({
    int discoveryPort = 7835,
  }) async* {
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
  Future<void> fetchData() async {
  }

  @override
  Future<void> startListening() async {
  }

  @override
  Future<void> startServer(int peerNetPort, int discoveryPort,
      {
        required Future<String> Function() onGetDBHash,
        required Future<int> Function() onGetDBCount}) async {
  }

  @override
  Future<void> synchronizeDB() async {
  }


}
