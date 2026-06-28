import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/services/order_lifecycle.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(isarProvider));
});

final orderListProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).watchAll();
});

final orderDetailProvider =
    FutureProvider.family<Order?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).findById(orderId);
});

final orderItemsProvider =
    FutureProvider.family<List<OrderItem>, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).findItemsByOrderId(orderId);
});

final orderActionsProvider =
    Provider.family<List<OrderAction>, Order>((ref, order) {
  final role = ref.watch(currentUserProvider).role;
  return OrderLifecycle.availableActions(order, role);
});

final placeOrderProvider = Provider<PlaceOrderController>((ref) {
  return PlaceOrderController(ref);
});

class PlaceOrderController {
  PlaceOrderController(this._ref);

  final Ref _ref;

  Future<Order> place(PlaceOrderInput input) {
    return _ref.read(orderRepositoryProvider).placeOrder(input);
  }

  Future<Order> update(UpdateOrderInput input) {
    return _ref.read(orderRepositoryProvider).updateOrderFromCart(input);
  }

  Future<Order> advance({
    required String orderId,
    required OrderStatus targetStatus,
    PaymentType? paymentType,
  }) {
    return _ref.read(orderRepositoryProvider).advanceStatus(
          orderId: orderId,
          targetStatus: targetStatus,
          role: _ref.read(currentUserProvider).role,
          deviceId: _ref.read(deviceIdProvider),
          paymentType: paymentType,
        );
  }

  Future<Order> markPaid({
    required String orderId,
    required PaymentType paymentType,
  }) {
    return _ref.read(orderRepositoryProvider).markPaid(
          orderId: orderId,
          paymentType: paymentType,
          role: _ref.read(currentUserProvider).role,
          deviceId: _ref.read(deviceIdProvider),
        );
  }

  Future<Order> cancel({
    required String orderId,
    required String reason,
    String? refundNote,
  }) {
    return _ref.read(orderRepositoryProvider).cancelOrder(
          orderId: orderId,
          reason: reason,
          refundNote: refundNote,
          role: _ref.read(currentUserProvider).role,
          deviceId: _ref.read(deviceIdProvider),
        );
  }

  Future<Order> setHeld({
    required String orderId,
    required bool isHeld,
  }) {
    return _ref.read(orderRepositoryProvider).setHeld(
          orderId: orderId,
          isHeld: isHeld,
          deviceId: _ref.read(deviceIdProvider),
        );
  }

  String get deviceId => _ref.read(deviceIdProvider);

  String get createdByUserId => _ref.read(currentUserProvider).id;

  UserRole get role => _ref.read(currentUserProvider).role;
}
