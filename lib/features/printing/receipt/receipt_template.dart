import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'receipt_data.dart';
import 'receipt_preview.dart';

/// Builds ESC/POS byte payloads for customer receipts.
abstract final class ReceiptTemplate {
  static Future<Uint8List> buildBytes(CustomerReceiptData receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[];

    if (receipt.isReprint) {
      bytes += generator.text(
        '*** REPRINT ***',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1,
      );
    }

    bytes += generator.text(
      receipt.businessName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'RECEIPT',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      receipt.orderNumber,
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(_timestamp(receipt.placedAt));
    bytes += generator.text(
      '${receipt.orderTypeLabel} · ${receipt.contextLabel}',
      linesAfter: 1,
    );
    bytes += generator.hr();

    for (final line in receipt.lines) {
      final label = line.variantName == null || line.variantName!.isEmpty
          ? line.name
          : '${line.name} (${line.variantName})';

      bytes += generator.row([
        PosColumn(
          text: '${line.quantity}x',
          width: 2,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(text: label, width: 6),
        PosColumn(
          text: formatReceiptMoney(line.lineTotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.text(
        '  @ ${formatReceiptMoney(line.unitPrice)} each',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );

      for (final modifier in line.modifiers) {
        final suffix = modifier.priceDelta == 0
            ? ''
            : ' ${formatReceiptMoney(modifier.priceDelta)}';
        bytes += generator.text('  + ${modifier.name}$suffix');
      }
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(
        text: formatReceiptMoney(receipt.subtotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (receipt.itemDiscountTotal > 0) {
      bytes += generator.row([
        PosColumn(text: 'Line discounts', width: 8),
        PosColumn(
          text: '-${formatReceiptMoney(receipt.itemDiscountTotal)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (receipt.orderDiscountTotal > 0) {
      bytes += generator.row([
        PosColumn(text: 'Order discount', width: 8),
        PosColumn(
          text: '-${formatReceiptMoney(receipt.orderDiscountTotal)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: formatReceiptMoney(receipt.total),
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.feed(1);
    bytes += generator.text('Payment: ${receipt.paymentTypeLabel}');
    bytes += generator.text('Status: ${receipt.paymentStatusLabel}');
    bytes += generator.feed(2);
    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  static String _timestamp(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
