import '../models/order_enums.dart';

/// Stamps per-status kitchen timestamps when an item advances on the KDS.
abstract final class KitchenStatusTimestamps {
  static void applyTransition({
    required KitchenStatus nextStatus,
    required DateTime now,
    required void Function(DateTime? value) setKitchenReadyAt,
    DateTime? currentKitchenReadyAt,
  }) {
    if (nextStatus == KitchenStatus.ready ||
        nextStatus == KitchenStatus.served) {
      setKitchenReadyAt(currentKitchenReadyAt ?? now);
    }
  }

  /// Resolves received time for kitchen performance reports.
  static DateTime resolveReceivedAt({
    required DateTime createdAt,
    DateTime? kitchenReceivedAt,
  }) {
    return kitchenReceivedAt ?? createdAt;
  }

  /// Resolves ready time; returns null when the item has not reached ready.
  static DateTime? resolveReadyAt({
    required KitchenStatus status,
    required DateTime kitchenStatusChangedAt,
    DateTime? kitchenReadyAt,
  }) {
    if (kitchenReadyAt != null) return kitchenReadyAt;
    if (status == KitchenStatus.ready || status == KitchenStatus.served) {
      return kitchenStatusChangedAt;
    }
    return null;
  }
}
