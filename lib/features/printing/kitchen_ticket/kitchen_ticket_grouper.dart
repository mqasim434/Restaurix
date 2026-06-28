import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import 'kitchen_ticket_data.dart';
import 'product_kitchen_meta.dart';

/// Builds printer jobs and category groups for kitchen tickets.
abstract final class KitchenTicketGrouper {
  static const uncategorizedLabel = 'General';

  static List<KitchenTicketPrintJob> buildPrintJobs({
    required Order order,
    required List<OrderItem> items,
    required Map<String, ProductKitchenMeta> productMetaById,
    required String? defaultPrinterId,
    required bool isReprint,
    required String contextLabel,
  }) {
    final activeItems = items.where((item) => item.deletedAt == null).toList();
    if (activeItems.isEmpty) return const [];

    final byPrinter = <String, List<_ItemWithMeta>>{};
    for (final item in activeItems) {
      final meta = item.productId != null
          ? productMetaById[item.productId!]
          : null;
      final printer = _resolvePrinter(
        meta: meta,
        defaultPrinterId: defaultPrinterId,
      );
      if (printer == null) continue;

      byPrinter.putIfAbsent(printer, () => []).add(_ItemWithMeta(item, meta));
    }

    return [
      for (final entry in byPrinter.entries)
        KitchenTicketPrintJob(
          printerTarget: entry.key,
          ticket: KitchenTicketData(
            orderNumber: order.orderNumber,
            contextLabel: contextLabel,
            placedAt: order.createdAt,
            notes: order.notes?.trim().isEmpty == true ? null : order.notes,
            isReprint: isReprint,
            categoryGroups: _categoryGroups(entry.value),
          ),
        ),
    ];
  }

  static List<String> collectMissingPrinterWarnings({
    required List<OrderItem> items,
    required Map<String, ProductKitchenMeta> productMetaById,
    required String? defaultPrinterId,
  }) {
    final warnings = <String>[];
    for (final item in items.where((i) => i.deletedAt == null)) {
      final meta = item.productId != null
          ? productMetaById[item.productId!]
          : null;
      if (_resolvePrinter(meta: meta, defaultPrinterId: defaultPrinterId) ==
          null) {
        warnings.add(
          'No kitchen printer configured for "${item.name}". '
          'Set a printer on the product or configure a default kitchen printer.',
        );
      }
    }
    return warnings;
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

  static String? _resolvePrinter({
    required ProductKitchenMeta? meta,
    required String? defaultPrinterId,
  }) {
    final productPrinter = meta?.printerId?.trim();
    if (productPrinter != null && productPrinter.isNotEmpty) {
      return productPrinter;
    }

    final fallback = defaultPrinterId?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
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
      modifierNames: [
        for (final modifier in item.modifiers) modifier.name,
      ],
    );
  }
}

class _ItemWithMeta {
  const _ItemWithMeta(this.item, this.meta);

  final OrderItem item;
  final ProductKitchenMeta? meta;
}
