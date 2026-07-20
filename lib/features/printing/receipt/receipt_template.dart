import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../core/constants.dart';
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

    var logoPrinted = false;
    try {
      final logo = await EscPosLogo.loadForThermal(
        maxWidth: (EscPosLogo.printWidthDots * 0.7).round(),
      );
      if (logo != null) {
        bytes += EscPosLogo.bytes(generator, logo);
        bytes += generator.feed(1);
        logoPrinted = true;
      }
    } catch (_) {
      logoPrinted = false;
    }
    if (!logoPrinted) {
      bytes += EscPosCommands.centered(
        generator,
        _t(receipt.businessName),
        bold: true,
        large: true,
        header: true,
      );
    }

    final phone = receipt.businessPhone?.trim().isNotEmpty == true
        ? receipt.businessPhone!.trim()
        : AppConstants.defaultBusinessPhone;
    final address = receipt.businessAddress?.trim().isNotEmpty == true
        ? receipt.businessAddress!.trim()
        : AppConstants.defaultBusinessAddress;

    bytes += EscPosCommands.centered(generator, _t(phone));
    for (final line in _addressLines(address)) {
      bytes += EscPosCommands.centered(generator, _t(line));
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
    bytes += EscPosCommands.fieldRow(
      generator,
      'Order Type',
      _t(receipt.orderTypeLabel),
    );
    final context = receipt.contextLabel.trim();
    if (context.startsWith('Table ')) {
      bytes += EscPosCommands.fieldRow(
        generator,
        'Table',
        _t(context.substring('Table '.length)),
      );
    }
    if (receipt.customerName != null &&
        receipt.customerName!.trim().isNotEmpty) {
      bytes += EscPosCommands.fieldRow(
        generator,
        'Customer',
        _t(receipt.customerName!.trim()),
      );
    }
    if (receipt.customerPhone != null &&
        receipt.customerPhone!.trim().isNotEmpty) {
      bytes += EscPosCommands.fieldRow(
        generator,
        'Phone',
        _t(receipt.customerPhone!.trim()),
      );
    }
    if (receipt.deliveryLocationLines.isNotEmpty) {
      for (var i = 0; i < receipt.deliveryLocationLines.length; i++) {
        bytes += EscPosCommands.fieldRow(
          generator,
          i == 0 ? 'Location' : '',
          _t(receipt.deliveryLocationLines[i]),
        );
      }
    }
    if (receipt.deliveryDistanceLabel != null) {
      bytes += EscPosCommands.fieldRow(
        generator,
        'Distance',
        receipt.deliveryDistanceLabel!,
      );
    }
    if (receipt.deliveryNotes != null &&
        receipt.deliveryNotes!.trim().isNotEmpty) {
      bytes += EscPosCommands.fieldRow(
        generator,
        'Loc. notes',
        _t(receipt.deliveryNotes!.trim()),
      );
    }
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

    if (receipt.serviceCharge > 0) {
      bytes += EscPosCommands.leftLine(
        generator,
        'Service Charges: ${money(receipt.serviceCharge)}',
      );
    }

    if (receipt.deliveryCharge > 0) {
      bytes += EscPosCommands.leftLine(
        generator,
        'Delivery Charges: ${money(receipt.deliveryCharge)}',
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

    final mapsPayload = receipt.mapsNavigationUrl?.trim();
    if (mapsPayload != null && mapsPayload.isNotEmpty) {
      bytes += EscPosCommands.divider(generator);
      bytes += EscPosCommands.centered(
        generator,
        'Scan for Google Maps',
        bold: true,
      );
      // Quiet zone above the symbol (thermal blur needs clear white margin).
      bytes += generator.feed(2);
      bytes += generator.qrcode(
        mapsPayload,
        align: PosAlign.center,
        // Larger modules = more physical dots per cell on ~203 DPI printers.
        size: QRSize.size7,
        // Highest recovery so muddy / missed dots still scan.
        cor: QRCorrection.H,
      );
      // Quiet zone below.
      bytes += generator.feed(2);
    }

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

  /// Split long address lines so they fit thermal paper width.
  static List<String> _addressLines(String address) {
    const maxLen = 42;
    final trimmed = address.trim();
    if (trimmed.length <= maxLen) return [trimmed];

    final comma = trimmed.lastIndexOf(',', maxLen);
    if (comma > 12) {
      return [
        trimmed.substring(0, comma + 1).trim(),
        trimmed.substring(comma + 1).trim(),
      ];
    }
    return [trimmed];
  }
}
