import '../../data/services/order_number_service.dart';
import '../models/order.dart';

/// Whether [order] is a remote live order (waiter tablet or customer app),
/// not created on this desktop device.
///
/// Used for Realtime alerts, auto-print, and the Live Orders board.
bool isTabletOrder(Order order, String localDeviceId) {
  if (isCustomerAppOrderNumber(order.orderNumber)) return true;
  if (isTabletOrderNumber(order.orderNumber)) return true;
  return order.deviceId.isNotEmpty && order.deviceId != localDeviceId;
}

/// Waiter / in-house tablet orders (`ODR-*` or foreign device, not customer app).
bool isWaiterTabletOrder(Order order, String localDeviceId) {
  if (isCustomerAppOrder(order)) return false;
  if (isTabletOrderNumber(order.orderNumber)) return true;
  return order.deviceId.isNotEmpty && order.deviceId != localDeviceId;
}

/// Customer mobile app orders (`ODRM-*`).
bool isCustomerAppOrder(Order order) =>
    isCustomerAppOrderNumber(order.orderNumber);

/// Realtime insert payload check before the order exists locally.
bool isTabletOrderPayload({
  required Map<String, dynamic> record,
  required String localDeviceId,
}) {
  final orderNumber = record['order_number']?.toString();
  if (orderNumber != null) {
    if (isCustomerAppOrderNumber(orderNumber)) return true;
    if (isTabletOrderNumber(orderNumber)) return true;
  }

  final deviceId = record['device_id']?.toString();
  return deviceId != null &&
      deviceId.isNotEmpty &&
      deviceId != localDeviceId;
}
