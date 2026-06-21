import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/navigation_provider.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(isarProvider));
});

final orderDetailProvider =
    FutureProvider.family<Order?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).findById(orderId);
});

final orderItemsProvider =
    FutureProvider.family<List<OrderItem>, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).findItemsByOrderId(orderId);
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

  String get deviceId => _ref.read(deviceIdProvider);

  String get createdByUserId => _ref.read(currentUserProvider).id;
}
