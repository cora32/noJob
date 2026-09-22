import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';

class PeerNetComms implements IPeerNetComms {
  final String _ip;
  final int _port;
  late WebSocket _socket;
  final _completers = <Completer<dynamic>>[];

  PeerNetComms(this._ip, this._port) {
    _socket.listen(
      (msg) {
        if (_completers.isNotEmpty) {
          final completer = _completers.removeAt(0);
          completer.complete(msg);
        }
      },
      onDone: () {
        for (var c in _completers) {
          c.completeError(Exception("Connection closed"));
        }
        _completers.clear();
      },
    );
  }

  Future<WebSocket> connect() async {
    _socket = await WebSocket.connect('ws://$_ip:$_port');

    return _socket;
  }

  Future<dynamic> _send(String msg) {
    final completer = Completer<dynamic>();
    _completers.add(completer);
    _socket.add(msg);
    return completer.future;
  }

  @override
  Future<PeerData> getInfo() async {
    final response = await _send(MsgTypes.GetInfo.name);
    return PeerData.fromJson(jsonDecode(response.toString()));
  }

  @override
  Future<void> disconnect() async {
    await _socket.close();
  }
}

extension CommsExt on PeerData {
  Future<T> use<T>({int port = 7834,
    required Future<T> Function(IPeerNetComms comms) block}) async {
    final comms = PeerNetComms(ip, port);

    try {
      await comms.connect();

      return await block(comms);
    } finally {
      await comms.disconnect();
    }
  }
}
