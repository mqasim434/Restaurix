enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

enum DeliveryMode {
  ownRider,
  pickupCompany,
}

enum PaymentType {
  cash,
  card,
  online,
  credit,
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
  served,
  paid,
  completed,
  cancelled,
}

enum KitchenStatus {
  received,
  preparing,
  ready,
  served,
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

  bool get defaultIsPrepaid => switch (this) {
        OrderType.dineIn => false,
        OrderType.takeaway => true,
        OrderType.delivery => true,
      };
}

extension DeliveryModeX on DeliveryMode {
  String get wireValue => switch (this) {
        DeliveryMode.ownRider => 'own_rider',
        DeliveryMode.pickupCompany => 'pickup_company',
      };

  String get label => switch (this) {
        DeliveryMode.ownRider => 'Own Rider',
        DeliveryMode.pickupCompany => 'Pickup Company',
      };
}

extension PaymentTypeX on PaymentType {
  String get label => switch (this) {
        PaymentType.cash => 'Cash',
        PaymentType.card => 'Card',
        PaymentType.online => 'Online',
        PaymentType.credit => 'On Credit',
      };

  bool get isCreditAccount => this == PaymentType.credit;
}

extension OrderPaymentStatusX on OrderPaymentStatus {
  bool get isSettled => this == OrderPaymentStatus.paid;
}

extension OrderStatusX on OrderStatus {
  bool get isClosed =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
}

extension KitchenStatusX on KitchenStatus {
  String get label => switch (this) {
        KitchenStatus.received => 'Received',
        KitchenStatus.preparing => 'Preparing',
        KitchenStatus.ready => 'Ready',
        KitchenStatus.served => 'Served',
      };
}
