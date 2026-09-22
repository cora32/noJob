import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/shared/logger.dart';
import 'package:nojob/shared/providers.dart';
import 'package:peernet/server/data/peernet_factory.dart';

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

  final peerNet = getPeerNet();

  // Start node
  await peerNet.startServer(peerNetPort, discoveryPort,
      onGetDBHash: () async {
        return await db.calculateFullDBHashPaged();
      },
      onGetDBCount: () async {
        return await jRepo.countTotal();
      });

  // Request db update
  await peerNet.synchronizeDB();
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
    l.e('[PeerNet]: Failed to start server: $e');
  }
}

// //----------------------Peer scan--------------------------
//
// Future<void> _scanForPeers() async {
//   final peerNet = getPeerNet(
//   );
//
//   await for (final peer in peerNet.discover()) {
//     l.i("[PeerNet] Discovered: ${peer.ip}");
//
//     final comms = await peerNet.connect(peer.ip, port: peerNetPort);
//     final version = await comms.getInfo();
//
//     "[PeerNet] Peer ${peer.ip} version: ${version.dbVersion}; timestamp: ${version.dbTimestamp}"
//         .e;
//
//     await comms.disconnect();
//   }
// }
//
// // Node scanner
// Future<void> startPeerNodesDiscovery() async {
//   try {
//     await Isolate.run(() => _scanForPeers());
//   } catch (e) {
//     l.e('[PeerNet]: Failed to start peer discovery: $e');
//   }
// }
