import 'dart:typed_data';

import 'package:windows_printer/windows_printer.dart';

import 'esc_pos_network_transport.dart';
import 'printer_target_parser.dart';

/// Sends raw ESC/POS bytes to a Windows-installed printer by name.
///
/// Requires [useRawDatatype: true] so the spooler does not reinterpret ESC/POS
/// commands as plain text (see windows_printer package docs).
class EscPosWindowsTransport implements EscPosTransport {
  @override
  bool supports(String target) => !PrinterTargetParser.isNetworkTarget(target);

  @override
  Future<void> send({
    required String target,
    required Uint8List bytes,
  }) async {
    await WindowsPrinter.printRawData(
      printerName: target.trim(),
      data: bytes,
      useRawDatatype: true,
    );
  }
}
