import 'package:intl/intl.dart';

import '../../../core/printing/esc_pos_money_format.dart';
import '../../../domain/models/app_currency.dart';
import 'receipt_data.dart';

String formatReceiptMoney(double amount, String currencyCode) {
  return EscPosMoneyFormat.format(
    amount,
    AppCurrency.normalizeCode(currencyCode),
  );
}

/// Plain-text preview of a customer receipt — used in tests.
abstract final class ReceiptPreview {
  static List<String> renderLines(CustomerReceiptData receipt) {
    final lines = <String>[];

    if (receipt.isReprint) {
      lines.add('*** REPRINT ***');
    }

    lines.add('[LOGO]');
    if (receipt.businessAddress != null &&
        receipt.businessAddress!.trim().isNotEmpty) {
      lines.add(receipt.businessAddress!.trim());
    }
    if (receipt.receiptHeaderText != null &&
        receipt.receiptHeaderText!.trim().isNotEmpty) {
      lines.add(receipt.receiptHeaderText!.trim());
    }
    lines.add('RECEIPT');
    lines.add(receipt.orderNumber);
    lines.add(
      DateFormat.yMMMd().add_jm().format(receipt.placedAt),
    );
    lines.add('${receipt.orderTypeLabel} · ${receipt.contextLabel}');
    lines.add('');

    for (final line in receipt.lines) {
      final variantSuffix =
          line.variantName == null ? '' : ' (${line.variantName})';
      lines.add('${line.quantity}x ${line.name}$variantSuffix');
      lines.add(
        '   ${formatReceiptMoney(line.unitPrice, receipt.currencyCode)} = '
        '${formatReceiptMoney(line.lineTotal, receipt.currencyCode)}',
      );
    }

    lines.add('');
    lines.add('Subtotal: ${formatReceiptMoney(receipt.subtotal, receipt.currencyCode)}');
    if (receipt.itemDiscountTotal > 0) {
      lines.add(
        'Line discounts: ${EscPosMoneyFormat.formatDiscount(receipt.itemDiscountTotal, receipt.currencyCode)}',
      );
    }
    if (receipt.orderDiscountTotal > 0) {
      lines.add(
        'Order discount: ${EscPosMoneyFormat.formatDiscount(receipt.orderDiscountTotal, receipt.currencyCode)}',
      );
    }
    lines.add('TOTAL: ${formatReceiptMoney(receipt.total, receipt.currencyCode)}');
    lines.add('Payment: ${receipt.paymentTypeLabel}');
    lines.add('Status: ${receipt.paymentStatusLabel}');
    if (receipt.receiptFooterText != null &&
        receipt.receiptFooterText!.trim().isNotEmpty) {
      lines.add(receipt.receiptFooterText!.trim());
    }

    return lines;
  }
}
