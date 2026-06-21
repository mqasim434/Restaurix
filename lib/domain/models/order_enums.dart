enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

enum DeliveryMode {
  ownRider,
  pickupCompany,
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

  String get label => switch (this) {
        OrderType.dineIn => 'Dine In',
        OrderType.takeaway => 'Take Away',
        OrderType.delivery => 'Delivery',
      };
}

extension DeliveryModeX on DeliveryMode {
  String get label => switch (this) {
        DeliveryMode.ownRider => 'Own Rider',
        DeliveryMode.pickupCompany => 'Pickup Company',
      };
}

extension OrderPaymentStatusX on OrderPaymentStatus {
  bool get isSettled => this == OrderPaymentStatus.paid;
}

extension OrderStatusX on OrderStatus {
  bool get isClosed =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
}
