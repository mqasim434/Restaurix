enum TableStatus {
  available,
  occupied,
}

extension TableStatusX on TableStatus {
  String get label => switch (this) {
        TableStatus.available => 'Available',
        TableStatus.occupied => 'Occupied',
      };

  /// Maps wire/DB values, including legacy `reserved`, into the two statuses.
  static TableStatus fromWire(String? value, {String? currentOrderId}) {
    switch (value) {
      case 'occupied':
        return TableStatus.occupied;
      case 'available':
        return TableStatus.available;
      case 'reserved':
        // Legacy hold: keep occupied only if an order is linked.
        final linked = currentOrderId != null && currentOrderId.isNotEmpty;
        return linked ? TableStatus.occupied : TableStatus.available;
      default:
        return TableStatus.available;
    }
  }
}
