import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range_utils.dart';
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

/// Date filter for the Orders list (defaults to today).
class OrdersListFilter {
  OrdersListFilter({
    this.preset = SalesDateRangePreset.today,
    DateTime? selectedDay,
    this.customStart,
    this.customEnd,
  }) : selectedDay = startOfLocalDay(selectedDay ?? DateTime.now());

  final SalesDateRangePreset preset;

  /// Day shown when [preset] is [SalesDateRangePreset.today] (supports prev/next).
  final DateTime selectedDay;
  final DateTime? customStart;
  final DateTime? customEnd;

  SalesDateRange resolve({DateTime? now}) {
    final anchor = now ?? DateTime.now();
    return switch (preset) {
      SalesDateRangePreset.today => SalesDateRange(
          preset: SalesDateRangePreset.today,
          startInclusive: startOfLocalDay(selectedDay),
          endExclusive: endOfLocalDayExclusive(selectedDay),
        ),
      SalesDateRangePreset.thisWeek ||
      SalesDateRangePreset.thisMonth =>
        resolveSalesDateRange(preset: preset, now: anchor),
      SalesDateRangePreset.custom => resolveSalesDateRange(
          preset: SalesDateRangePreset.custom,
          customStart: customStart,
          customEnd: customEnd,
          now: anchor,
        ),
    };
  }

  bool get isBrowsingToday {
    if (preset != SalesDateRangePreset.today) return false;
    return startOfLocalDay(selectedDay) == startOfLocalDay(DateTime.now());
  }

  bool get canGoNextDay {
    if (preset != SalesDateRangePreset.today) return false;
    return startOfLocalDay(selectedDay).isBefore(startOfLocalDay(DateTime.now()));
  }

  OrdersListFilter copyWith({
    SalesDateRangePreset? preset,
    DateTime? selectedDay,
    DateTime? customStart,
    DateTime? customEnd,
    bool clearCustom = false,
  }) {
    return OrdersListFilter(
      preset: preset ?? this.preset,
      selectedDay: selectedDay ?? this.selectedDay,
      customStart: clearCustom ? null : (customStart ?? this.customStart),
      customEnd: clearCustom ? null : (customEnd ?? this.customEnd),
    );
  }
}

final ordersListFilterProvider = StateProvider<OrdersListFilter>((ref) {
  return OrdersListFilter();
});

final filteredOrderListProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final filter = ref.watch(ordersListFilterProvider);
  final range = filter.resolve();
  return ref.watch(orderListProvider).whenData(
        (orders) =>
            orders.where((order) => range.contains(order.createdAt)).toList(),
      );
});

final orderDetailProvider =
    FutureProvider.family<Order?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).findById(orderId);
});

final orderItemsProvider =
    StreamProvider.family<List<OrderItem>, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchItemsByOrderId(orderId);
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

  Future<Order> confirmLiveOrderBill({
    required String orderId,
    required double serviceCharge,
    required double deliveryCharge,
  }) {
    return _ref.read(orderRepositoryProvider).confirmLiveOrderBill(
          orderId: orderId,
          serviceCharge: serviceCharge,
          deliveryCharge: deliveryCharge,
          deviceId: _ref.read(deviceIdProvider),
        );
  }

  Future<Order> completeCreditOrder({required String orderId}) {
    return _ref.read(orderRepositoryProvider).completeCreditOrder(
          orderId: orderId,
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
