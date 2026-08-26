import 'package:peernet/server/i_peernet.dart';
import 'package:peernet/server/peernet_stub.dart'
    if (dart.library.io) 'package:peernet/server/peernet_default.dart';

PeerNet getPeerNet() => getInstance();
