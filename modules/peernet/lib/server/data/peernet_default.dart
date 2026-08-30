import 'dart:convert';
import 'dart:io';

import 'package:peernet/server/data/peernet_comms.dart';
import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/transfer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

PeerNet getInstance() => PeerNetDefault();

class PeerNetDefault implements PeerNet {
  static final PeerNetDefault _instance = PeerNetDefault._();

  PeerNetDefault._();

  factory PeerNetDefault() => _instance;

  RawDatagramSocket? _udpSocket;
  bool _isStarted = false;

  @override
  DataCallback? onGetSyncData;
  @override
  VersionDataCallback? onGetVersion;

  late final _handler = webSocketHandler((ws, protocol) {
    ws.stream.listen((msg) async {
      print("WS handler: $msg");

      if (msg == MsgTypes.getSyncData.name) {
        if (onGetSyncData != null) {
          final response = await onGetSyncData!(null);
          ws.sink.add(response);
        }
      } else if (msg == MsgTypes.getVersionData.name) {
        if (onGetVersion != null) {
          final response = await onGetVersion!(null);
          ws.sink.add(json.encode(response.toJson()));
        }
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
    print("UDP: Starting discovery scan on port $discoveryPort...");
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket.receive();
        if (dg != null) {
          final message = String.fromCharCodes(dg.data);
          if (message == 'PEER_HERE') {
            print("UDP: Found peer at ${dg.address.address}");
            callback(PeerData(ip: dg.address.address));
          }
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
  Future<void> start(int peerNetPort, int discoveryPort) async {
    if (_isStarted) return;
    _isStarted = true;

    _peerNetPort = peerNetPort;
    _discoveryPort = discoveryPort;

    print(
      "Starting WS server on port $_peerNetPort; discoveryPort: $_discoveryPort...",
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
              print("UDP: Responding to discovery from ${dg.address.address}");
              _udpSocket?.send('PEER_HERE'.codeUnits, dg.address, dg.port);
            }
          }
        }
      });
    } catch (e) {
      print("Failed to start server: $e");
    }
  }

  @override
  Future<IPeerNetComms> connect(String ip, {int port = 7834}) async {
    print("WS: Connecting to $ip:$port...");
    final ws = await WebSocket.connect('ws://$ip:$port');
    return PeerNetComms(socket: ws);
  }
}
