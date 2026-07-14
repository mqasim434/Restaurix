import 'dart:typed_data';

import 'esc_pos_network_transport.dart';
import 'esc_pos_windows_transport.dart';

/// Routes print jobs to network or Windows spooler transports.
///
/// An empty [target] sends to the Windows default printer.
class EscPosTransportRouter implements EscPosTransport {
  EscPosTransportRouter({
    EscPosNetworkTransport? network,
    EscPosWindowsTransport? windows,
  })  : _network = network ?? EscPosNetworkTransport(),
        _windows = windows ?? EscPosWindowsTransport();

  final EscPosNetworkTransport _network;
  final EscPosWindowsTransport _windows;

  @override
  bool supports(String target) {
    return _network.supports(target) || _windows.supports(target);
  }

  @override
  Future<void> send({
    required String target,
    required Uint8List bytes,
  }) async {
    if (target.trim().isEmpty) {
      await _windows.send(target: target, bytes: bytes);
      return;
    }
    if (_network.supports(target)) {
      await _network.send(target: target, bytes: bytes);
      return;
    }
    if (_windows.supports(target)) {
      await _windows.send(target: target, bytes: bytes);
      return;
    }
    throw EscPosTransportException('Unsupported printer target: $target');
  }
}

class EscPosTransportException implements Exception {
  EscPosTransportException(this.message);

  final String message;

  @override
  String toString() => message;
}
