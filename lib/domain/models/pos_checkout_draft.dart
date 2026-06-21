import 'order_enums.dart';

/// In-progress order metadata alongside the cart — separate from line items.
class PosCheckoutDraft {
  const PosCheckoutDraft({
    this.orderType,
    this.tableId,
    this.tableLabel,
    this.deliveryMode,
    this.riderId,
    this.riderName,
    this.pickupCompanyId,
    this.pickupCompanyName,
  });

  final OrderType? orderType;
  final String? tableId;
  final String? tableLabel;
  final DeliveryMode? deliveryMode;
  final String? riderId;
  final String? riderName;
  final String? pickupCompanyId;
  final String? pickupCompanyName;

  PosCheckoutDraft copyWith({
    OrderType? orderType,
    bool clearOrderType = false,
    String? tableId,
    String? tableLabel,
    bool clearTable = false,
    DeliveryMode? deliveryMode,
    bool clearDeliveryMode = false,
    String? riderId,
    String? riderName,
    bool clearRider = false,
    String? pickupCompanyId,
    String? pickupCompanyName,
    bool clearPickupCompany = false,
  }) {
    return PosCheckoutDraft(
      orderType: clearOrderType ? null : (orderType ?? this.orderType),
      tableId: clearTable ? null : (tableId ?? this.tableId),
      tableLabel: clearTable ? null : (tableLabel ?? this.tableLabel),
      deliveryMode:
          clearDeliveryMode ? null : (deliveryMode ?? this.deliveryMode),
      riderId: clearRider ? null : (riderId ?? this.riderId),
      riderName: clearRider ? null : (riderName ?? this.riderName),
      pickupCompanyId:
          clearPickupCompany ? null : (pickupCompanyId ?? this.pickupCompanyId),
      pickupCompanyName: clearPickupCompany
          ? null
          : (pickupCompanyName ?? this.pickupCompanyName),
    );
  }
}
