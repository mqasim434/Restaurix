import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../system_printer.dart';
import 'kitchen_ticket_data.dart';
import 'product_kitchen_meta.dart';

/// Builds kitchen ticket jobs grouped by category on the system default printer.
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

    final entries = [
      for (final item in activeItems)
        _ItemWithMeta(
          item,
          item.productId != null ? productMetaById[item.productId!] : null,
        ),
    ];

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
          categoryGroups: _categoryGroups(entries),
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

  static List<KitchenTicketCategoryGroup> _categoryGroups(
    List<_ItemWithMeta> items,
  ) {
    final grouped = <String, List<KitchenTicketLine>>{};

    for (final entry in items) {
      final category = _categoryLabel(entry.meta);
      grouped.putIfAbsent(category, () => []).add(_toLine(entry.item));
    }

    final labels = grouped.keys.toList()..sort();
    return [
      for (final label in labels)
        KitchenTicketCategoryGroup(
          categoryLabel: label,
          lines: grouped[label]!,
        ),
    ];
  }

  static String _categoryLabel(ProductKitchenMeta? meta) {
    final category = meta?.kitchenCategory?.trim();
    if (category == null || category.isEmpty) return uncategorizedLabel;
    return category;
  }

  static KitchenTicketLine _toLine(OrderItem item) {
    return KitchenTicketLine(
      name: item.name,
      variantName: item.variantName,
      quantity: item.quantity,
    );
  }
}

class _ItemWithMeta {
  const _ItemWithMeta(this.item, this.meta);

  final OrderItem item;
  final ProductKitchenMeta? meta;
}
