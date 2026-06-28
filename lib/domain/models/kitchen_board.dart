import 'order_enums.dart';

/// Kitchen-safe line item — no prices or payment data.
class KitchenDisplayItem {
  const KitchenDisplayItem({
    required this.id,
    required this.name,
    this.variantName,
    required this.quantity,
    this.modifierNames = const [],
    required this.kitchenStatus,
    required this.prepMinutes,
    required this.kitchenStatusChangedAt,
  });

  final String id;
  final String name;
  final String? variantName;
  final int quantity;
  final List<String> modifierNames;
  final KitchenStatus kitchenStatus;
  final int prepMinutes;
  final DateTime kitchenStatusChangedAt;
}

/// One order card within a KDS column.
class KitchenOrderCard {
  const KitchenOrderCard({
    required this.orderId,
    required this.orderNumber,
    required this.contextLabel,
    required this.isHeld,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  final String orderId;
  final String orderNumber;
  final String contextLabel;
  final bool isHeld;
  final String? notes;
  final DateTime createdAt;
  final List<KitchenDisplayItem> items;
}

/// Three-column kitchen board snapshot.
class KitchenBoard {
  const KitchenBoard({
    this.incoming = const [],
    this.preparing = const [],
    this.ready = const [],
  });

  final List<KitchenOrderCard> incoming;
  final List<KitchenOrderCard> preparing;
  final List<KitchenOrderCard> ready;
}
