import 'dart:io';
import 'dart:typed_data';

import 'printer_target_parser.dart';

/// Sends raw ESC/POS bytes to a network thermal printer (TCP port 9100).
abstract interface class EscPosTransport {
  Future<void> send({
    required String target,
    required Uint8List bytes,
  });

  bool supports(String target);
}

class EscPosNetworkTransport implements EscPosTransport {
  EscPosNetworkTransport({this.timeout = const Duration(seconds: 5)});

  final Duration timeout;

  @override
  bool supports(String target) => PrinterTargetParser.isNetworkTarget(target);

  @override
  Future<void> send({
    required String target,
    required Uint8List bytes,
  }) async {
    final parsed = PrinterTargetParser.parseNetwork(target);
    Socket? socket;
    try {
      socket = await Socket.connect(
        parsed.host,
        parsed.port,
        timeout: timeout,
      );
      socket.add(bytes);
      await socket.flush();
    } finally {
      await socket?.close();
    }
  }
}
