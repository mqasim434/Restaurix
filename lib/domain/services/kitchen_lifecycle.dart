import '../models/kitchen_board.dart';
import '../models/order.dart';
import '../models/order_enums.dart';
import '../models/order_item.dart';

/// Per-item kitchen prep rules and order-status sync derived from item states.
abstract final class KitchenLifecycle {
  static bool isOrderVisibleOnKitchen(Order order) {
    if (order.deletedAt != null) return false;

    return switch (order.status) {
      OrderStatus.received ||
      OrderStatus.preparing ||
      OrderStatus.ready =>
        true,
      _ => false,
    };
  }

  static bool isItemVisibleOnKitchen(OrderItem item) {
    if (item.deletedAt != null) return false;

    return switch (item.kitchenStatus) {
      KitchenStatus.received ||
      KitchenStatus.preparing ||
      KitchenStatus.ready =>
        true,
      KitchenStatus.served => false,
    };
  }

  static KitchenStatus? nextItemStatus(KitchenStatus current) {
    return switch (current) {
      KitchenStatus.received => KitchenStatus.preparing,
      KitchenStatus.preparing => KitchenStatus.ready,
      KitchenStatus.ready || KitchenStatus.served => null,
    };
  }

  static String advanceItemLabel(KitchenStatus current) {
    return switch (current) {
      KitchenStatus.received => 'Start',
      KitchenStatus.preparing => 'Mark Ready',
      KitchenStatus.ready || KitchenStatus.served => '',
    };
  }

  /// Derives the parent order status from active item kitchen statuses.
  static OrderStatus? deriveOrderStatus(Order order, List<OrderItem> items) {
    final active = items.where(isItemVisibleOnKitchen).toList();
    if (active.isEmpty) return null;

    final allReady = active.every(
      (item) => item.kitchenStatus == KitchenStatus.ready,
    );
    if (allReady &&
        (order.status == OrderStatus.received ||
            order.status == OrderStatus.preparing)) {
      return OrderStatus.ready;
    }

    final anyStarted = active.any(
      (item) => item.kitchenStatus != KitchenStatus.received,
    );
    if (anyStarted && order.status == OrderStatus.received) {
      return OrderStatus.preparing;
    }

    return null;
  }

  static KitchenBoard buildBoard({
    required List<Order> orders,
    required Map<String, List<OrderItem>> itemsByOrderId,
    required Map<String, String> tableLabelsById,
  }) {
    final incoming = <KitchenOrderCard>[];
    final preparing = <KitchenOrderCard>[];
    final ready = <KitchenOrderCard>[];

    for (final order in orders) {
      if (!isOrderVisibleOnKitchen(order)) continue;

      final items = itemsByOrderId[order.id] ?? const [];
      final visibleItems = items.where(isItemVisibleOnKitchen).toList();
      if (visibleItems.isEmpty) continue;

      final contextLabel = _contextLabel(order, tableLabelsById);
      final notes = order.notes?.trim().isEmpty == true ? null : order.notes;

      void addColumn(
        KitchenStatus status,
        List<KitchenOrderCard> target,
      ) {
        final columnItems = visibleItems
            .where((item) => item.kitchenStatus == status)
            .map(_toDisplayItem)
            .toList();
        if (columnItems.isEmpty) return;

        target.add(
          KitchenOrderCard(
            orderId: order.id,
            orderNumber: order.orderNumber,
            contextLabel: contextLabel,
            isHeld: order.isHeld,
            notes: notes,
            createdAt: order.createdAt,
            items: columnItems,
          ),
        );
      }

      addColumn(KitchenStatus.received, incoming);
      addColumn(KitchenStatus.preparing, preparing);
      addColumn(KitchenStatus.ready, ready);
    }

    int compareCards(KitchenOrderCard a, KitchenOrderCard b) {
      if (a.isHeld != b.isHeld) {
        return a.isHeld ? -1 : 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    }

    incoming.sort(compareCards);
    preparing.sort(compareCards);
    ready.sort(compareCards);

    return KitchenBoard(
      incoming: incoming,
      preparing: preparing,
      ready: ready,
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

  static KitchenDisplayItem _toDisplayItem(OrderItem item) {
    return KitchenDisplayItem(
      id: item.id,
      name: item.name,
      variantName: item.variantName,
      quantity: item.quantity,
      modifierNames: [
        for (final modifier in item.modifiers) modifier.name,
      ],
      kitchenStatus: item.kitchenStatus,
      prepMinutes: item.prepMinutes,
      kitchenStatusChangedAt: item.kitchenStatusChangedAt,
    );
  }
}
