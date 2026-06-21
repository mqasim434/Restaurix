import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/pos_checkout_draft.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../tables/providers/table_providers.dart';
import '../services/checkout_validation.dart';
import 'cart_providers.dart';

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, PosCheckoutDraft>(CheckoutNotifier.new);

final checkoutValidationErrorProvider = Provider<String?>((ref) {
  final draft = ref.watch(checkoutProvider);
  final cartEmpty = ref.watch(cartProvider).isEmpty;
  if (cartEmpty) return null;
  return CheckoutValidation.validate(draft);
});

final posAvailableTablesProvider = StreamProvider<List<RestaurantTable>>((ref) {
  return ref.watch(tableRepositoryProvider).watchAvailableForPos();
});

class CheckoutNotifier extends Notifier<PosCheckoutDraft> {
  TableRepository get _tables => ref.read(tableRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  PosCheckoutDraft build() {
    ref.listen(cartProvider, (previous, next) {
      if (next.isEmpty) {
        final tableId = state.tableId;
        state = const PosCheckoutDraft();
        if (tableId != null) {
          unawaited(
            _tables.releaseCheckoutReservation(
              tableId: tableId,
              deviceId: _deviceId,
            ),
          );
        }
      }
    });

    return const PosCheckoutDraft();
  }

  Future<void> setOrderType(OrderType type) async {
    if (state.orderType == OrderType.dineIn && type != OrderType.dineIn) {
      await _releaseTableIfNeeded(state.tableId);
    }

    state = state.copyWith(
      orderType: type,
      clearTable: type != OrderType.dineIn,
      clearDeliveryMode: type != OrderType.delivery,
      clearRider: type != OrderType.delivery,
      clearPickupCompany: type != OrderType.delivery,
    );
  }

  Future<void> selectTable({
    required String tableId,
    required String tableLabel,
  }) async {
    if (state.tableId == tableId) return;

    await _releaseTableIfNeeded(state.tableId);
    await _tables.reserveForCheckout(tableId: tableId, deviceId: _deviceId);

    state = state.copyWith(
      orderType: OrderType.dineIn,
      tableId: tableId,
      tableLabel: tableLabel,
    );
  }

  void setDeliveryMode(DeliveryMode mode) {
    state = state.copyWith(
      deliveryMode: mode,
      clearRider: mode != DeliveryMode.ownRider,
      clearPickupCompany: mode != DeliveryMode.pickupCompany,
    );
  }

  void selectRider({required String id, required String name}) {
    state = state.copyWith(
      deliveryMode: DeliveryMode.ownRider,
      riderId: id,
      riderName: name,
      clearPickupCompany: true,
    );
  }

  void selectPickupCompany({required String id, required String name}) {
    state = state.copyWith(
      deliveryMode: DeliveryMode.pickupCompany,
      pickupCompanyId: id,
      pickupCompanyName: name,
      clearRider: true,
    );
  }

  Future<void> clear() async {
    await _releaseTableIfNeeded(state.tableId);
    state = const PosCheckoutDraft();
  }

  Future<void> _releaseTableIfNeeded(String? tableId) async {
    if (tableId == null) return;
    await _tables.releaseCheckoutReservation(
      tableId: tableId,
      deviceId: _deviceId,
    );
  }
}
