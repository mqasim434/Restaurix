import 'package:intl/intl.dart';

import 'receipt_data.dart';

String formatReceiptMoney(double amount) {
  return NumberFormat.simpleCurrency().format(amount);
}

/// Plain-text preview of a customer receipt — used in tests.
abstract final class ReceiptPreview {
  static List<String> renderLines(CustomerReceiptData receipt) {
    final lines = <String>[];

    if (receipt.isReprint) {
      lines.add('*** REPRINT ***');
    }

    lines.add(receipt.businessName);
    lines.add('RECEIPT');
    lines.add(receipt.orderNumber);
    lines.add(
      DateFormat.yMMMd().add_jm().format(receipt.placedAt),
    );
    lines.add('${receipt.orderTypeLabel} · ${receipt.contextLabel}');

    for (final line in receipt.lines) {
      final label = line.variantName == null || line.variantName!.isEmpty
          ? line.name
          : '${line.name} (${line.variantName})';
      lines.add(
        '${line.quantity}x $label  '
        '${formatReceiptMoney(line.unitPrice)} = '
        '${formatReceiptMoney(line.lineTotal)}',
      );
      for (final modifier in line.modifiers) {
        final delta = modifier.priceDelta == 0
            ? ''
            : ' (${formatReceiptMoney(modifier.priceDelta)})';
        lines.add('   + ${modifier.name}$delta');
      }
    }

    lines.add('Subtotal: ${formatReceiptMoney(receipt.subtotal)}');
    if (receipt.itemDiscountTotal > 0) {
      lines.add(
        'Line discounts: -${formatReceiptMoney(receipt.itemDiscountTotal)}',
      );
    }
    if (receipt.orderDiscountTotal > 0) {
      lines.add(
        'Order discount: -${formatReceiptMoney(receipt.orderDiscountTotal)}',
      );
    }
    lines.add('TOTAL: ${formatReceiptMoney(receipt.total)}');
    lines.add('Payment: ${receipt.paymentTypeLabel}');
    lines.add('Status: ${receipt.paymentStatusLabel}');

    return lines;
  }
}
