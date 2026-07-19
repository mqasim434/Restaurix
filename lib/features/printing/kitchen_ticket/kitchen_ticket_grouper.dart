import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../system_printer.dart';
import 'kitchen_ticket_data.dart';
import 'product_kitchen_meta.dart';

/// Builds kitchen ticket jobs on the system default printer.
abstract final class KitchenTicketGrouper {
  static const uncategorizedLabel = 'General';

  static List<KitchenTicketPrintJob> buildPrintJobs({
    required Order order,
    required List<OrderItem> items,
    required Map<String, ProductKitchenMeta> productMetaById,
    required bool isReprint,
    required String contextLabel,
  }) {
    final activeItems = items.where((item) => item.deletedAt == null).toList();
    if (activeItems.isEmpty) return const [];

    // Single flat list — category labels are not printed on kitchen tickets.
    final lines = [for (final item in activeItems) _toLine(item)];

    return [
      KitchenTicketPrintJob(
        printerTarget: SystemPrinter.defaultTarget,
        ticket: KitchenTicketData(
          orderNumber: order.orderNumber,
          orderTypeLabel: order.orderType.label,
          contextLabel: contextLabel,
          placedAt: order.createdAt,
          notes: order.notes?.trim().isEmpty == true ? null : order.notes,
          isReprint: isReprint,
          categoryGroups: [
            KitchenTicketCategoryGroup(
              categoryLabel: uncategorizedLabel,
              lines: lines,
            ),
          ],
        ),
      ),
    ];
  }

  static String contextLabel({
    required Order order,
    required Map<String, String> tableLabelsById,
  }) {
    return switch (order.orderType) {
      OrderType.dineIn => order.tableId == null
          ? 'Dine In'
          : 'Table ${tableLabelsById[order.tableId] ?? order.tableId}',
      OrderType.takeaway => 'Take Away',
      OrderType.delivery => 'Delivery',
    };
  }

  static KitchenTicketLine _toLine(OrderItem item) {
    return KitchenTicketLine(
      name: item.name,
      variantName: item.variantName,
      quantity: item.quantity,
    );
  }
}
