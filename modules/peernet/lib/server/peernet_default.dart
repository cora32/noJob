import 'dart:io';

import 'package:peernet/server/i_peernet.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

PeerNet getInstance() => PeerNetDefault();

class PeerNetDefault implements PeerNet {
  @override
  GetSyncDataCallback? onGetSyncData;

  late final _handler = webSocketHandler((ws, protocol) {
    ws.stream.listen((msg) async {
      print("WS: $msg");

      if (msg == MsgTypes.getSyncData.name) {
        if (onGetSyncData != null) {
          final response = await onGetSyncData!(null);
          ws.sink.add(response);
        }
      } else {
        ws.sink.add("Echo: $msg");
      }
    });
  });

  @override
  Future<void> start(int port) async {
    print("Starting WS server...");
    try {
      await shelf_io.serve(_handler, InternetAddress.anyIPv4, port);
    } catch (e) {
      print("Failed to start server: $e");
    }
  }
}
