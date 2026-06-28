import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/services/order_lifecycle.dart';
import 'receipt_data.dart';

/// Builds receipt snapshots directly from persisted order records.
abstract final class ReceiptBuilder {
  static CustomerReceiptData fromPersisted({
    required Order order,
    required List<OrderItem> items,
    required String businessName,
    required Map<String, String> tableLabelsById,
    bool isReprint = false,
  }) {
    final activeItems = items.where((item) => item.deletedAt == null).toList();

    return CustomerReceiptData(
      businessName: businessName,
      orderNumber: order.orderNumber,
      orderTypeLabel: order.orderType.label,
      contextLabel: _contextLabel(order, tableLabelsById),
      placedAt: order.createdAt,
      lines: [for (final item in activeItems) _toLine(item)],
      subtotal: order.subtotal,
      itemDiscountTotal: order.itemDiscountTotal,
      orderDiscountTotal: order.orderDiscountTotal,
      total: order.total,
      paymentTypeLabel: order.paymentType?.label ?? '—',
      paymentStatusLabel: order.paymentStatus.label,
      isReprint: isReprint,
    );
  }

  static String _contextLabel(
    Order order,
    Map<String, String> tableLabelsById,
  ) {
    return switch (order.orderType) {
      OrderType.dineIn => order.tableId == null
          ? 'Dine In'
          : 'Table ${tableLabelsById[order.tableId] ?? order.tableId}',
      OrderType.takeaway => 'Take Away',
      OrderType.delivery => 'Delivery',
    };
  }

  static ReceiptLine _toLine(OrderItem item) {
    return ReceiptLine(
      name: item.name,
      variantName: item.variantName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      lineTotal: item.lineTotal,
      modifiers: [
        for (final modifier in item.modifiers)
          ReceiptModifierLine(
            name: modifier.name,
            priceDelta: modifier.priceDelta,
          ),
      ],
    );
  }
}

/// Determines when customer receipts should auto-print.
abstract final class ReceiptPrintPolicy {
  static bool shouldAutoPrint(Order order) {
    if (order.status == OrderStatus.cancelled) return false;
    return order.paymentStatus.isSettled;
  }
}
