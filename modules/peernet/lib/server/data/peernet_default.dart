import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:peernet/server/data/discovery_server/discovery_api.dart';
import 'package:peernet/server/data/peernet_comms.dart';
import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:snapshot_system/data/storage.dart';
import 'package:snapshot_system/domain/peer_data_hash.dart';
import 'package:snapshot_system/domain/snapshot.dart';

PeerNet getInstance({IStorage storage = const Storage()}) =>
    PeerNetDefault.getInstance(storage: storage);

class PeerNetDefault implements PeerNet {
  final _logger = Logger(printer: PrettyPrinter());
  final IStorage _storage;
  final int _discoveryPort;
  static PeerNetDefault? _instance;
  late ISnapshot _snapshot;
  late IDiscoveryApi _discoveryApi;

  PeerNetDefault._({
    this._storage = const Storage(),
    this._discoveryPort = 7835,
  }) : _discoveryApi = DiscoveryApi(discoveryPort: _discoveryPort);

  factory PeerNetDefault.getInstance({IStorage storage = const Storage()}) {
    _instance ??= PeerNetDefault._();
    return _instance!;
  }

  bool _isStarted = false;
  int _peerNetPort = 0;

  int getUptime() {
    return 0;
  }

  late final _handler = webSocketHandler((ws, protocol) {
    ws.stream.listen((msg) async {
      _logger.i("[PeerNet]: New message: $msg");

      if (msg == MsgTypes.GetInfo.name) {
        final snapshotHash = await _snapshot.getHashFromSnapshot();
        final dbHash = await _snapshot.getHashFromDB();

        ws.sink.add(json.encode(PeerData(
            ip: "",
            uptime: getUptime(),
            dbHash: dbHash,
            snapshotHash: snapshotHash).toJson()));
      } else {
        ws.sink.add("Echo: $msg");
      }
    });
  });

  @override
  Stream<PeerData> discover({int discoveryPort = 7835}) async* {
    yield* _discoveryApi.discover();
  }

  @override
  Future<void> startServer(int peerNetPort,
      int discoveryPort, {
        int snapshotVersion = 1,
        required Future<String> Function() onGetDBHash,
        required Future<int> Function() onGetDBCount,
      }) async {
    if (_isStarted) return;
    _isStarted = true;

    _peerNetPort = peerNetPort;
    _snapshot = Snapshot(
      snapshotVersion,
      _storage,
      onGetDBHash: onGetDBHash,
      onGetDBCount: onGetDBCount,
    );

    _logger.i(
      "[PeerNet]: Starting WS server on port $_peerNetPort; discoveryPort: $_discoveryPort...",
    );

    // 1. TCP Server (WebSocket)
    await shelf_io.serve(_handler, InternetAddress.anyIPv4, _discoveryPort);

    // 2. UDP Discovery Responder
    await _discoveryApi.start();
  }

  Stream<PeerData> _discoverPeers() async* {
    _logger.i("[PeerNet]: Discovering peers...");
    yield* discover();
  }

  Future<List<PeerData>> _getPeerInfo(List<PeerData> peers) async {
    _logger.i("[PeerNet]: Requesting stats for ${peers.length} peers...");

    final stats = <PeerData>[];
    for (final peer in peers) {
      _logger.i("[PeerNet]: Requesting peer ${peer.ip}...");

      try {
        final peerInfo = await peer.use<PeerData>(
          block: (IPeerNetComms comms) async {
            return await comms.getInfo();
          },
        );

        stats.add(peerInfo);

        _logger.i(
          "[PeerNet]: Peer: ${peer.ip}; uptime: ${peerInfo
              .uptime}; dbHash: ${peerInfo.dbHash}; snapshotHash: ${peerInfo
              .snapshotHash}",
        );
      } catch (e) {
        _logger.e("[PeerNet]: Failed to connect to $peer: $e");
      }
    }

    return stats;
  }

  Future<List<PeerData>> _fetchPeerInfo() async {
    // Discovered peers
    final peers = await _discoverPeers().toList();

    if (peers.isEmpty) {
      _logger.i("[PeerNet]: No peers detected.");

      return [];
    }

    // Get peer statistics
    final stats = await _getPeerInfo(peers);

    return stats;
  }

  @override
  Future<void> synchronizeDB() async {
    // Get peers
    final peers = await _fetchPeerInfo();

    if (peers.isEmpty) {
      return;
    }

    final peerHashes = peers
        .map(
          (peer) =>
          PeerDataHash(
            dbHash: peer.dbHash,
            snapshotHash: peer.snapshotHash,
            uptime: peer.uptime,
          ),
    )
        .toList();

    // Decide replication action
    final action = await _snapshot.getReplicationStrategy(peerHashes);

    switch (action) {
    // Get full DB + Snapshot
      case FullReplication fullReplica:
        {
          _logger.i("[PeerNet]: Strategy: Full Replication");

          // await fetchData();
          break;
        }
    // Request only chunks from Snapshot
      case PartialFetch partialFetch:
        {
          _logger.i("[PeerNet]: Strategy: Partial fetch");

          final startFrom = partialFetch.startFromTimestamp;

          break;
        }
      default:
        {
          _logger.i("[PeerNet]: Strategy: No Replication");
        }
    }
  }
}
