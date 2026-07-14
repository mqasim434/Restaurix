import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../core/printing/esc_pos_commands.dart';
import '../../../core/printing/esc_pos_logo.dart';
import '../../../core/printing/esc_pos_money_format.dart';
import '../../../core/printing/esc_pos_text_sanitizer.dart';
import 'receipt_data.dart';

/// Builds ESC/POS byte payloads for customer receipts (80 mm).
abstract final class ReceiptTemplate {
  static String _t(String value) => EscPosTextSanitizer.sanitize(value);

  static Future<Uint8List> buildBytes(CustomerReceiptData receipt) async {
    String money(double amount) =>
        EscPosMoneyFormat.format(amount, receipt.currencyCode);

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[]
      ..addAll(EscPosCommands.init(generator));

    if (receipt.isReprint) {
      bytes += EscPosCommands.centered(
        generator,
        '*** REPRINT ***',
        bold: true,
      );
    }

    final logo = await EscPosLogo.loadForThermal();
    if (logo != null) {
      bytes += EscPosLogo.bytes(generator, logo);
      bytes += generator.feed(1);
    } else {
      bytes += EscPosCommands.centered(
        generator,
        _t(receipt.businessName),
        bold: true,
        large: true,
        header: true,
      );
    }

    if (receipt.businessAddress != null &&
        receipt.businessAddress!.trim().isNotEmpty) {
      bytes += EscPosCommands.centered(
        generator,
        _t(receipt.businessAddress!.trim()),
      );
    }

    if (receipt.receiptHeaderText != null &&
        receipt.receiptHeaderText!.trim().isNotEmpty) {
      bytes += EscPosCommands.centered(
        generator,
        _t(receipt.receiptHeaderText!.trim()),
      );
    }

    bytes += EscPosCommands.divider(generator);
    bytes += EscPosCommands.centered(generator, 'RECEIPT', bold: true);
    bytes += EscPosCommands.divider(generator);

    bytes += EscPosCommands.fieldRow(
      generator,
      'Order',
      _t(receipt.orderNumber),
    );
    bytes += EscPosCommands.fieldRow(
      generator,
      'Date',
      _timestamp(receipt.placedAt),
    );
    bytes += EscPosCommands.leftLine(
      generator,
      '${_t(receipt.orderTypeLabel)}  ${_t(receipt.contextLabel)}',
    );
    bytes += EscPosCommands.divider(generator);

    for (final line in receipt.lines) {
      final label = line.variantName == null || line.variantName!.isEmpty
          ? _t(line.name)
          : _t('${line.name} (${line.variantName})');

      bytes += EscPosCommands.priceRow(
        generator,
        '${line.quantity}x $label',
        money(line.lineTotal),
      );
      bytes += EscPosCommands.detailLine(
        generator,
        '   ${money(line.unitPrice)} each',
      );
    }

    bytes += EscPosCommands.divider(generator);
    bytes += EscPosCommands.priceRow(
      generator,
      'Subtotal',
      money(receipt.subtotal),
      bold: false,
    );

    if (receipt.itemDiscountTotal > 0) {
      bytes += EscPosCommands.priceRow(
        generator,
        'Discounts',
        EscPosMoneyFormat.formatDiscount(
          receipt.itemDiscountTotal,
          receipt.currencyCode,
        ),
        bold: false,
      );
    }

    if (receipt.orderDiscountTotal > 0) {
      bytes += EscPosCommands.priceRow(
        generator,
        'Order disc.',
        EscPosMoneyFormat.formatDiscount(
          receipt.orderDiscountTotal,
          receipt.currencyCode,
        ),
        bold: false,
      );
    }

    bytes += EscPosCommands.priceRow(
      generator,
      'TOTAL',
      money(receipt.total),
    );
    bytes += EscPosCommands.divider(generator);
    bytes += EscPosCommands.fieldRow(
      generator,
      'Payment',
      _t(receipt.paymentTypeLabel),
    );
    bytes += EscPosCommands.fieldRow(
      generator,
      'Status',
      _t(receipt.paymentStatusLabel),
    );

    final footer = receipt.receiptFooterText?.trim().isNotEmpty == true
        ? _t(receipt.receiptFooterText!.trim())
        : 'Thank you!';
    bytes += EscPosCommands.centered(generator, footer);

    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  static String _timestamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
