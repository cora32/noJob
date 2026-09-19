import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:peernet/server/data/peernet_comms.dart';
import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';
import 'package:peernet/server/domain/peer_net_message.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:snapshot_system/data/storage.dart';
import 'package:snapshot_system/domain/snapshot_system.dart';

PeerNet getInstance({
  int snapshotVersion = 1,
  IStorage storage = const Storage(),
  required FutureOr<String> Function() calculateHashForDB,
  required FutureOr<int> Function() getDBCount,
}) =>
    PeerNetDefault.getInstance(
      snapshotVersion: snapshotVersion,
      storage: storage,
      calculateHashForDB: calculateHashForDB,
      getDBCount: getDBCount,
    );

class PeerNetDefault implements PeerNet {
  final _logger = Logger(printer: PrettyPrinter());
  static PeerNetDefault? _instance;
  final ISnapshotSystem _snapshot;

  PeerNetDefault._(this._snapshot);

  factory PeerNetDefault.getInstance({
    int snapshotVersion = 1,
    IStorage storage = const Storage(),
    required FutureOr<String> Function() calculateHashForDB,
    required FutureOr<int> Function() getDBCount,
  }) {
    _instance ??= PeerNetDefault._(
      SnapshotSystem(snapshotVersion,
          storage,
          calculateHashForDB,
          getDBCount),
    );
    return _instance!;
  }

  RawDatagramSocket? _udpSocket;
  bool _isStarted = false;

  // @override
  // DataCallback? onGetSyncData;
  // @override
  // VersionDataCallback? onGetPeerData;
  // @override
  // FutureOr<int> Function()? getCount;
  // @override
  // FutureOr<String> Function()? calculateHashForDB;

  late final _handler = webSocketHandler((ws, protocol) {
    ws.stream.listen((msg) async {
      _logger.i("[PeerNet]: New message: $msg");

      if (msg == MsgTypes.getSyncData.name) {
        // if (onGetSyncData != null) {
        //   final response = await onGetSyncData!(null);
        //   ws.sink.add(response);
        // }
      } else if (msg == MsgTypes.getVersionData.name) {
        // if (onGetVersion != null) {
        //   final response = await onGetVersion!(null);
        //   ws.sink.add(json.encode(response.toJson()));
        // }
      } else {
        ws.sink.add("Echo: $msg");
      }
    });
  });

  int _peerNetPort = 0;
  int _discoveryPort = 0;

  @override
  Future<void> discover(
    OnPeerFoundCallback callback, {
    int discoveryPort = 7835,
  }) async {
    _logger.i("[PeerNet]: Starting discovery scan on port $discoveryPort...");
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        try {
          final dg = socket.receive();

          if (dg != null) {
            final jsonString = String.fromCharCodes(dg.data);
            final peerNetMessage = PeerNetMessage.fromJson(
              jsonDecode(jsonString),
            );

            if (peerNetMessage.message == CommandMessages.peerHere) {
              _logger.i("[PeerNet]: Found peer at ${dg.address.address}");

              final peerData = PeerData.fromJson(
                jsonDecode(peerNetMessage.json),
              );

              callback(
                PeerData(
                  ip: dg.address.address,
                  uptime: peerData.uptime,
                  dbVersion: peerData.dbVersion,
                  dbTimestamp: peerData.dbTimestamp,
                  dbHash: peerData.dbHash,
                  snapshotHash: peerData.snapshotHash,
                ),
              );
            }
          }
        } catch (e) {
          _logger.i("[PeerNet]: Error while parsing inbound message: $e");
        }
      }
    });

    // Broadcast discovery message to the whole network
    final data = 'PEER_LOOKUP'.codeUnits;
    socket.send(data, InternetAddress('255.255.255.255'), discoveryPort);

    // Close the scanning socket after a short period
    Future.delayed(const Duration(seconds: 5), () => socket.close());
  }

  @override
  Future<void> startServer(int peerNetPort, int discoveryPort) async {
    if (_isStarted) return;
    _isStarted = true;

    _peerNetPort = peerNetPort;
    _discoveryPort = discoveryPort;

    _logger.i(
      "[PeerNet]: Starting WS server on port $_peerNetPort; discoveryPort: $_discoveryPort...",
    );
    try {
      // 1. TCP Server (WebSocket)
      await shelf_io.serve(_handler, InternetAddress.anyIPv4, _peerNetPort);

      // 2. UDP Discovery Responder
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
      );
      _udpSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpSocket?.receive();
          if (dg != null) {
            final message = String.fromCharCodes(dg.data);
            if (message == 'PEER_LOOKUP') {
              _logger.i(
                "[PeerNet]: Responding to discovery from ${dg.address.address}",
              );
              _udpSocket?.send('PEER_HERE'.codeUnits, dg.address, dg.port);
            }
          }
        }
      });
    } catch (e) {
      _logger.e("[PeerNet]: Failed to start server: $e");
    }
  }

  @override
  Future<IPeerNetComms> connect(String ip, {int port = 7834}) async {
    _logger.i("[PeerNet]: Connecting to $ip:$port...");
    final ws = await WebSocket.connect('ws://$ip:$port');
    return PeerNetComms(socket: ws);
  }

  Future<List<PeerData>> _discoverPeers() async {
    _logger.i("[PeerNet]: Discovering peers...");
    final peers = <PeerData>[];
    await discover((peer) async {
      _logger.i("[PeerNet]: Peer added: ${peer.ip}");
      peers.add(peer);
    });

    // Wait 5 seconds for peers to respond
    await Future.delayed(Duration(seconds: 5));

    return peers;
  }

  Future<List<PeerData>> _getPeerStatistics(List<PeerData> peers) async {
    _logger.i("[PeerNet]: Requesting stats for ${peers.length} peers...");

    final stats = <PeerData>[];
    for (final peer in peers) {
      _logger.i("[PeerNet]: Requesting peer ${peer.ip}...");

      try {
        final comms = await connect(peer.ip);
        final peerData = await comms.getVersionData();
        stats.add(peerData);

        _logger.i(
          "[PeerNet]: Peer: ${peer.ip}: dbVersion: ${peerData.dbVersion}",
        );

        await comms.disconnect();
      } catch (e) {
        _logger.e("[PeerNet]: Failed to connect to $peer: $e");
      }
    }

    return stats;
  }

  Future<ReplicationStrategy> _getReplicationStrategy(
      List<PeerData> peers,) async {
    final count = _snapshot.getDBCount();
    final isDbEmpty = count == 0;
    final todayMinus7 = DateTime
        .now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final lastSyncTimestamp = await _snapshot.getLastSyncTimestamp();
    final isTooOld = lastSyncTimestamp >= todayMinus7;
    final dbHash = await _snapshot.getHashFromDB();
    final snapshotHash = await _snapshot.getHashFromSnapshot();

    peers.sort((a, b) => b.uptime.compareTo(a.uptime));
    var isUpToDate = true;
    for (final peer in peers) {
      if (dbHash != peer.dbHash || snapshotHash != peer.snapshotHash) {
        isUpToDate = false;
        break;
      }
    }

    _logger.i("[PeerNet]: DB count: $count\n"
        " isDbEmpty: $isDbEmpty\n"
        " isTooOld: $isTooOld\n"
        " isUpToDate: $isUpToDate\n"
        " lastSyncTimestamp: $lastSyncTimestamp");

    if (isDbEmpty || isTooOld || lastSyncTimestamp == 0) {
      return FullReplication();
    } else if (isUpToDate) {
      return NoReplication();
    } else {
      return PartialFetch(lastSyncTimestamp);
    }
  }

  Future<List<PeerData>> _getPeers() async {
    // Discovered peers
    final peers = await _discoverPeers();

    // Get peer statistics
    final stats = await _getPeerStatistics(peers);

    return stats;
  }

  Future<void> synchronizeDB() async {
    // Get peers
    final peers = await _getPeers();

    // Decide replication action
    final action = await _getReplicationStrategy(peers);

    switch (action) {
    // Get full DB + Snapshot
      case FullReplication fullReplica:
        {
          _logger.i("[PeerNet]: Strategy: Full Replication");

          await fetchData();
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

  @override
  Future<void> startListening() {
    // TODO: implement startListening
    throw UnimplementedError();
  }

  @override
  Future<void> fetchData() {
    // TODO: implement fetchData
    throw UnimplementedError();
  }
}
