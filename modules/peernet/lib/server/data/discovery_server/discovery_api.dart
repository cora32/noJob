import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:peernet/server/domain/i_peernet.dart';
import 'package:peernet/server/domain/peer_data.dart';
import 'package:peernet/server/domain/peer_net_message.dart';

abstract interface class IDiscoveryApi {
  Future<void> start();

  Stream<PeerData> discover();
}

class DiscoveryApi implements IDiscoveryApi {
  final _logger = Logger(printer: PrettyPrinter());

  final int _discoveryPort;
  RawDatagramSocket? _udpSocket;

  DiscoveryApi({this._discoveryPort = 7835});

  @override
  Future<void> start() async {
    try {
      // Get all local IPv4 addresses to filter out self
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final localIps = interfaces
          .expand((interface) => interface.addresses)
          .map((addr) => addr.address)
          .toSet();

      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
      );
      _udpSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpSocket?.receive();
          if (dg != null) {
            // Filter out messages from this device
            if (localIps.contains(dg.address.address)) {
              return;
            }

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
  Stream<PeerData> discover() async* {
    _logger.i("[PeerNet]: Broadcasting discovery message...");

    // Get all local IPv4 addresses to filter out self
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final localIps = interfaces
        .expand((interface) => interface.addresses)
        .map((addr) => addr.address)
        .toSet();

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    // Broadcast discovery message to the whole network
    final data = 'PEER_LOOKUP'.codeUnits;
    socket.send(data, InternetAddress('255.255.255.255'), _discoveryPort);

    // Close the scanning socket after a short period
    final timer = Timer(const Duration(seconds: 5), () => socket.close());

    try {
      await for (final event in socket) {
        if (event == RawSocketEvent.read) {
          try {
            final dg = socket.receive();

            if (dg != null) {
              final remoteIp = dg.address.address;

              // Filter out messages from this device
              if (localIps.contains(remoteIp)) {
                continue;
              }

              final jsonString = String.fromCharCodes(dg.data);
              final peerNetMessage = PeerNetMessage.fromJson(
                jsonDecode(jsonString),
              );

              if (peerNetMessage.message == CommandMessages.PeerHere) {
                _logger.i("[PeerNet]: Found peer at $remoteIp");

                final peerData = PeerData.fromJson(
                  jsonDecode(peerNetMessage.json),
                );

                yield PeerData(
                  ip: remoteIp,
                  uptime: peerData.uptime,
                  dbHash: peerData.dbHash,
                  snapshotHash: peerData.snapshotHash,
                );
              }
            }
          } catch (e) {
            _logger.i("[PeerNet]: Error while parsing inbound message: $e");
          }
        }
      }
    } finally {
      timer.cancel();
      socket.close();
    }
  }
}
