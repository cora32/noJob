import 'dart:async';
import 'dart:io';

import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/transfer.dart';

class PeerNetComms implements IPeerNetComms {
  final WebSocket _socket;
  final _completers = <Completer<dynamic>>[];

  PeerNetComms({required this._socket}) {
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

  Future<dynamic> _send(String msg) {
    final completer = Completer<dynamic>();
    _completers.add(completer);
    _socket.add(msg);
    return completer.future;
  }

  @override
  Future<String> getSyncData() async {
    final response = await _send(MsgTypes.getSyncData.name);
    return response.toString();
  }

  @override
  Future<VersionData> getVersionData() async {
    final response = await _send(MsgTypes.getVersionData.name);
    return VersionData.fromJson(response.toString());
  }

  @override
  Future<void> disconnect() async {
    await _socket.close();
  }
}
