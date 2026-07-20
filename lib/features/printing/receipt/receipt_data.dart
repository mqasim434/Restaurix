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
    this.businessPhone,
    this.businessAddress,
    required this.orderNumber,
    required this.orderTypeLabel,
    required this.contextLabel,
    this.customerName,
    this.customerPhone,
    this.deliveryLocationLines = const [],
    this.deliveryNotes,
    this.deliveryDistanceKm,
    this.mapsNavigationUrl,
    required this.placedAt,
    required this.lines,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.orderDiscountTotal,
    this.serviceCharge = 0,
    this.deliveryCharge = 0,
    required this.total,
    required this.paymentTypeLabel,
    required this.paymentStatusLabel,
    this.isReprint = false,
    required this.currencyCode,
  });

  final String businessName;
  final String? businessPhone;
  final String? businessAddress;
  final String? receiptHeaderText;
  final String? receiptFooterText;
  final String orderNumber;
  final String orderTypeLabel;
  final String contextLabel;
  final String? customerName;
  final String? customerPhone;
  final List<String> deliveryLocationLines;
  final String? deliveryNotes;
  final double? deliveryDistanceKm;
  /// QR payload for delivery navigation (short lat,lng or Maps query).
  final String? mapsNavigationUrl;
  final DateTime placedAt;

  String? get deliveryDistanceLabel {
    if (deliveryDistanceKm == null) return null;
    final km = deliveryDistanceKm!;
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(0)} km';
  }
  final List<ReceiptLine> lines;
  final double subtotal;
  final double itemDiscountTotal;
  final double orderDiscountTotal;
  final double serviceCharge;
  final double deliveryCharge;
  final double total;
  final String paymentTypeLabel;
  final String paymentStatusLabel;
  final bool isReprint;
  final String currencyCode;
}
