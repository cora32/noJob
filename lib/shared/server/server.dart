import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/providers.dart';
import 'package:peernet/server/data/peernet_factory.dart';
import 'package:peernet/server/domain/peer_data.dart';

const peerNetPort = 7834;
const discoveryPort = 7835;

//----------------------Server--------------------------

Future<void> serverEntryPoint(Map<String, dynamic> config) async {
  final String dbPath = config['dbPath'];
  DatabaseService.setDatabasePath(dbPath);

  final container = ProviderContainer();
  final jRepo = container.read(jobRepo);
  final db = container.read(dbService);
  // final prefs = await SharedPreferences.getInstance();

  final peerNet = getPeerNet(
      calculateHashForDB: () async {
        return await db.calculateFullDBHashPaged();
      },
      getDBCount: () async {
        return await jRepo.countTotal();
    }
  );

  await peerNet.startServer(peerNetPort, discoveryPort);
}

// Server
void startPeerNet(String dbPath) {
  final rcvPort = ReceivePort();

  try {
    Isolate.spawn(serverEntryPoint, {
      'sendPort': rcvPort.sendPort,
      'dbPath': dbPath,
    });
  } catch (e) {
    "PeerNet: Failed to start server: $e".e;
  }
}

//----------------------Peer scan--------------------------

Future<void> _scanForPeers(Map<String, dynamic> data) async {
  final sendPort = data['sendPort'] as SendPort;

  final peerNet = getPeerNet(
      calculateHashForDB: () async {
        return "";
      },
      getDBCount: () async {
        return 0;
      }
  );
  await peerNet.discover((PeerData peer) async {
    "[PeerNet] Discovered: ${peer.ip}".e;

    final comms = await peerNet.connect(peer.ip, port: peerNetPort);
    final version = await comms.getVersionData();

    "[PeerNet] Peer ${peer.ip} version: ${version.dbVersion}; timestamp: ${version.dbTimestamp}"
        .e;

    await comms.disconnect();
  });
}

// Node scanner
void startPeerNodesDiscovery() {
  final rcvPort = ReceivePort();

  try {
    Isolate.spawn(_scanForPeers, {"sendPort": rcvPort.sendPort});
  } catch (e) {
    "PeerNet: Failed to start server: $e".e;
  }
}
