import 'package:peernet/server/i_peernet.dart';

PeerNet getInstance() => PeerNetStub();

class PeerNetStub implements PeerNet {
  @override
  GetSyncDataCallback? onGetSyncData;

  @override
  Future<void> start(int port) async {
    // Noop for web target
  }
}
