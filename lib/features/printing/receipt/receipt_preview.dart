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
    if (receipt.businessPhone != null &&
        receipt.businessPhone!.trim().isNotEmpty) {
      lines.add(receipt.businessPhone!.trim());
    }
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
    lines.add('Order Type: ${receipt.orderTypeLabel}');
    final context = receipt.contextLabel.trim();
    if (context.startsWith('Table ')) {
      lines.add('Table: ${context.substring('Table '.length)}');
    }
    if (receipt.customerName != null &&
        receipt.customerName!.trim().isNotEmpty) {
      lines.add('Customer: ${receipt.customerName!.trim()}');
    }
    if (receipt.customerPhone != null &&
        receipt.customerPhone!.trim().isNotEmpty) {
      lines.add('Phone: ${receipt.customerPhone!.trim()}');
    }
    if (receipt.deliveryLocationLines.isNotEmpty) {
      lines.add('Location: ${receipt.deliveryLocationLines.first}');
      for (final line in receipt.deliveryLocationLines.skip(1)) {
        lines.add(line);
      }
    }
    if (receipt.deliveryDistanceLabel != null) {
      lines.add('Distance: ${receipt.deliveryDistanceLabel}');
    }
    if (receipt.deliveryNotes != null &&
        receipt.deliveryNotes!.trim().isNotEmpty) {
      lines.add('Loc. notes: ${receipt.deliveryNotes!.trim()}');
    }
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
    if (receipt.serviceCharge > 0) {
      lines.add(
        'Service Charges: ${formatReceiptMoney(receipt.serviceCharge, receipt.currencyCode)}',
      );
    }
    if (receipt.deliveryCharge > 0) {
      lines.add(
        'Delivery Charges: ${formatReceiptMoney(receipt.deliveryCharge, receipt.currencyCode)}',
      );
    }
    lines.add('TOTAL: ${formatReceiptMoney(receipt.total, receipt.currencyCode)}');
    lines.add('Payment: ${receipt.paymentTypeLabel}');
    lines.add('Status: ${receipt.paymentStatusLabel}');
    if (receipt.receiptFooterText != null &&
        receipt.receiptFooterText!.trim().isNotEmpty) {
      lines.add(receipt.receiptFooterText!.trim());
    }
    if (receipt.mapsNavigationUrl != null &&
        receipt.mapsNavigationUrl!.trim().isNotEmpty) {
      lines.add('Scan for Google Maps');
      lines.add('[QR] ${receipt.mapsNavigationUrl}');
    }

    return lines;
  }
}
