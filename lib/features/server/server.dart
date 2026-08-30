import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/database_service.dart';
import 'package:nojob/features/home/presentation/providers/job_repo_provider.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:peernet/server/data/peernet_factory.dart';
import 'package:peernet/server/domain/transfer.dart';
import 'package:sqflite/sqflite.dart';

const peerNetPort = 7834;
const discoveryPort = 7835;

//----------------------Server--------------------------

Future<void> serverEntryPoint(Map<String, dynamic> config) async {
  final String dbPath = config['dbPath'];
  DatabaseService.setDatabasePath(dbPath);

  final container = ProviderContainer();
  final dbService = container.read(dbProvider);
  final jobRepo = container.read(jobRepoProvider);
  final db = await dbService.database;

  final peerNet = getPeerNet()
    ..onGetVersion = (data) async {
      "[Server] onGetVersion".e;
      final version = await db.getVersion();
      final lastTimestamp = await jobRepo.getLastTimestamp();

      return VersionData(dbVersion: version, dbTimestamp: lastTimestamp);
    }
    ..onGetSyncData = (data) async {
      "[Server] onGetSyncData".e;
      final results = await db.query('jobs');
      return "DB Items: ${results.length}";
    };

  await peerNet.start(peerNetPort, discoveryPort);
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

  final peerNet = getPeerNet();
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
