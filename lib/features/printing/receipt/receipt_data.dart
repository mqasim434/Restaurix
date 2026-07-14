/// Outcome of a receipt print attempt — warnings are non-fatal.
class ReceiptPrintResult {
  const ReceiptPrintResult({
    this.printed = false,
    this.warnings = const [],
  });

  final bool printed;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Customer receipt line — totals from persisted order item fields only.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
}

/// Full customer receipt snapshot built from a persisted order record.
class CustomerReceiptData {
  const CustomerReceiptData({
    required this.businessName,
    this.receiptHeaderText,
    this.receiptFooterText,
    this.businessAddress,
    required this.orderNumber,
    required this.orderTypeLabel,
    required this.contextLabel,
    required this.placedAt,
    required this.lines,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.orderDiscountTotal,
    required this.total,
    required this.paymentTypeLabel,
    required this.paymentStatusLabel,
    this.isReprint = false,
    required this.currencyCode,
  });

  final String businessName;
  final String? businessAddress;
  final String? receiptHeaderText;
  final String? receiptFooterText;
  final String orderNumber;
  final String orderTypeLabel;
  final String contextLabel;
  final DateTime placedAt;
  final List<ReceiptLine> lines;
  final double subtotal;
  final double itemDiscountTotal;
  final double orderDiscountTotal;
  final double total;
  final String paymentTypeLabel;
  final String paymentStatusLabel;
  final bool isReprint;
  final String currencyCode;
}
