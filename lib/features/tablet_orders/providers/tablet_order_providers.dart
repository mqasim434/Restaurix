import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/order.dart';
import '../../../domain/services/tablet_order_detection.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../../data/local/device_id_service.dart';

/// Order detected via Realtime before the local sync pull finishes.
@immutable
class PendingTabletOrder {
  const PendingTabletOrder({
    required this.orderId,
    required this.orderNumber,
    required this.detectedAt,
  });

  final String orderId;
  final String orderNumber;
  final DateTime detectedAt;
}

@immutable
class TabletOrderArrivalState {
  const TabletOrderArrivalState({
    this.pending = const [],
    this.highlightedOrderIds = const {},
  });

  final List<PendingTabletOrder> pending;
  final Set<String> highlightedOrderIds;

  TabletOrderArrivalState copyWith({
    List<PendingTabletOrder>? pending,
    Set<String>? highlightedOrderIds,
  }) {
    return TabletOrderArrivalState(
      pending: pending ?? this.pending,
      highlightedOrderIds: highlightedOrderIds ?? this.highlightedOrderIds,
    );
  }
}

/// Tracks in-flight tablet orders and highlights newly arrived rows.
final tabletOrderArrivalControllerProvider =
    StateNotifierProvider<TabletOrderArrivalController, TabletOrderArrivalState>(
  (ref) => TabletOrderArrivalController(),
);

class TabletOrderArrivalController extends StateNotifier<TabletOrderArrivalState> {
  TabletOrderArrivalController() : super(const TabletOrderArrivalState());

  void onOrderDetected({
    required String orderId,
    required String orderNumber,
  }) {
    if (state.pending.any((entry) => entry.orderId == orderId)) {
      state = state.copyWith(
        highlightedOrderIds: {...state.highlightedOrderIds, orderId},
      );
      return;
    }

    state = state.copyWith(
      pending: [
        PendingTabletOrder(
          orderId: orderId,
          orderNumber: orderNumber,
          detectedAt: DateTime.now(),
        ),
        ...state.pending,
      ],
      highlightedOrderIds: {...state.highlightedOrderIds, orderId},
    );
  }

  void reconcileSyncedOrders(List<Order> syncedOrders) {
    if (state.pending.isEmpty) return;

    final syncedIds = syncedOrders.map((order) => order.id).toSet();
    final remaining = state.pending
        .where((entry) => !syncedIds.contains(entry.orderId))
        .toList();

    if (remaining.length == state.pending.length) return;
    state = state.copyWith(pending: remaining);
  }

  void acknowledgeHighlight(String orderId) {
    if (!state.highlightedOrderIds.contains(orderId)) return;
    state = state.copyWith(
      highlightedOrderIds: {...state.highlightedOrderIds}..remove(orderId),
    );
  }
}

/// All remote live orders (waiter tablet + customer app).
final tabletOrderListProvider = StreamProvider<List<Order>>((ref) {
  final localDeviceId = ref.watch(deviceIdProvider);
  return ref
      .watch(orderRepositoryProvider)
      .watchTabletOrders(localDeviceId);
});

/// In-house waiter tablet orders only (`ODR-*` / foreign non-customer).
final waiterTabletOrderListProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final localDeviceId = ref.watch(deviceIdProvider);
  return ref.watch(tabletOrderListProvider).whenData(
        (orders) => orders
            .where((order) => isWaiterTabletOrder(order, localDeviceId))
            .toList(),
      );
});

/// Customer app orders only (`ODRM-*`).
final customerAppOrderListProvider = Provider<AsyncValue<List<Order>>>((ref) {
  return ref.watch(tabletOrderListProvider).whenData(
        (orders) => orders.where(isCustomerAppOrder).toList(),
      );
});

/// Tracks auto-print state for tablet orders (UI badges + deduplication).
final tabletOrderPrintTrackerProvider =
    StateNotifierProvider<TabletOrderPrintTracker, TabletOrderPrintState>(
  (ref) => TabletOrderPrintTracker(ref),
);

class TabletOrderPrintState {
  const TabletOrderPrintState({
    this.printedOrderIds = const {},
    this.pendingOrderIds = const {},
    this.failedOrderIds = const {},
  });

  final Set<String> printedOrderIds;
  final Set<String> pendingOrderIds;
  final Set<String> failedOrderIds;

  bool isPrinted(String orderId) => printedOrderIds.contains(orderId);
  bool isPending(String orderId) => pendingOrderIds.contains(orderId);
  bool hasFailed(String orderId) => failedOrderIds.contains(orderId);

  TabletOrderPrintState copyWith({
    Set<String>? printedOrderIds,
    Set<String>? pendingOrderIds,
    Set<String>? failedOrderIds,
  }) {
    return TabletOrderPrintState(
      printedOrderIds: printedOrderIds ?? this.printedOrderIds,
      pendingOrderIds: pendingOrderIds ?? this.pendingOrderIds,
      failedOrderIds: failedOrderIds ?? this.failedOrderIds,
    );
  }
}

class TabletOrderPrintTracker extends StateNotifier<TabletOrderPrintState> {
  TabletOrderPrintTracker(Ref ref) : super(const TabletOrderPrintState());

  void hydratePrintedIds(Set<String> ids) {
    state = state.copyWith(printedOrderIds: ids);
  }

  void markPending(String orderId) {
    if (state.isPrinted(orderId)) return;
    state = state.copyWith(
      pendingOrderIds: {...state.pendingOrderIds, orderId},
      failedOrderIds: {...state.failedOrderIds}..remove(orderId),
    );
  }

  void markPrinted(String orderId) {
    state = state.copyWith(
      printedOrderIds: {...state.printedOrderIds, orderId},
      pendingOrderIds: {...state.pendingOrderIds}..remove(orderId),
      failedOrderIds: {...state.failedOrderIds}..remove(orderId),
    );
  }

  void markFailed(String orderId) {
    state = state.copyWith(
      pendingOrderIds: {...state.pendingOrderIds}..remove(orderId),
      failedOrderIds: {...state.failedOrderIds, orderId},
    );
  }
}

bool isTabletOrderRecord(Order order, String localDeviceId) =>
    isTabletOrder(order, localDeviceId);
