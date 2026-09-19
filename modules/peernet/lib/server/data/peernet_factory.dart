import 'dart:async';

import 'package:peernet/server/data/peernet_stub.dart'
    if (dart.library.io) 'package:peernet/server/data/peernet_default.dart';
import 'package:peernet/server/domain/i_peernet.dart';
import 'package:snapshot_system/data/storage.dart';

PeerNet getPeerNet({
  int snapshotVersion = 1,
  IStorage storage = const Storage(),
  required FutureOr<String> Function() calculateHashForDB,
  required FutureOr<int> Function() getDBCount,
}) => getInstance(
  snapshotVersion: snapshotVersion,
  storage: storage,
  calculateHashForDB: calculateHashForDB,
  getDBCount: getDBCount,
);
