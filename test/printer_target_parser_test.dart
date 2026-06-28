import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/features/printing/kitchen_ticket/printer_target_parser.dart';

void main() {
  group('PrinterTargetParser', () {
    test('detects network targets', () {
      expect(PrinterTargetParser.isNetworkTarget('192.168.1.50'), isTrue);
      expect(PrinterTargetParser.isNetworkTarget('192.168.1.50:9100'), isTrue);
      expect(PrinterTargetParser.isNetworkTarget('Kitchen Printer'), isFalse);
    });

    test('parses host and port', () {
      expect(
        PrinterTargetParser.parseNetwork('192.168.1.50:9100'),
        (host: '192.168.1.50', port: 9100),
      );
      expect(
        PrinterTargetParser.parseNetwork('10.0.0.5'),
        (host: '10.0.0.5', port: 9100),
      );
    });
  });
}
