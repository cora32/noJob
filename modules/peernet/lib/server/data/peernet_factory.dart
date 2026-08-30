import 'package:peernet/server/data/peernet_stub.dart'
    if (dart.library.io) 'package:peernet/server/data/peernet_default.dart';
import 'package:peernet/server/domain/i_peernet.dart';

PeerNet getPeerNet() => getInstance();
