import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/transfer.dart';

PeerNet getInstance() => PeerNetStub();

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
  Future<VersionData> getVersionData() {
    // TODO: implement getVersionData
    throw UnimplementedError();
  }
}

class PeerNetStub implements PeerNet {
  static final PeerNetStub _instance = PeerNetStub._();

  PeerNetStub._();

  factory PeerNetStub() => _instance;

  @override
  DataCallback? onGetSyncData;
  @override
  VersionDataCallback? onGetVersion;

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
}
