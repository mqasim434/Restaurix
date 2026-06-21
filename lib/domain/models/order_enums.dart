enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

enum OrderPaymentStatus {
  unpaid,
  paid,
  refunded,
}

enum OrderStatus {
  received,
  preparing,
  ready,
  completed,
  cancelled,
}

extension OrderTypeX on OrderType {
  String get wireValue => switch (this) {
        OrderType.dineIn => 'dine_in',
        OrderType.takeaway => 'takeaway',
        OrderType.delivery => 'delivery',
      };
}

extension OrderPaymentStatusX on OrderPaymentStatus {
  bool get isSettled => this == OrderPaymentStatus.paid;
}

extension OrderStatusX on OrderStatus {
  bool get isClosed =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
}
