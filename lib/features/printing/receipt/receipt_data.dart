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

/// Customer receipt modifier line — prices from persisted order item data.
class ReceiptModifierLine {
  const ReceiptModifierLine({
    required this.name,
    required this.priceDelta,
  });

  final String name;
  final double priceDelta;
}

/// Customer receipt line — totals from persisted order item fields only.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.modifiers = const [],
  });

  final String name;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final List<ReceiptModifierLine> modifiers;
}

/// Full customer receipt snapshot built from a persisted order record.
class CustomerReceiptData {
  const CustomerReceiptData({
    required this.businessName,
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
  });

  final String businessName;
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
}
