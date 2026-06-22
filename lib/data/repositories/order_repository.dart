import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/discount.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_enums.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/pos_checkout_draft.dart';
import '../../domain/models/table_status.dart';
import '../../domain/models/user_role.dart';
import '../../domain/services/order_lifecycle.dart';
import '../../domain/services/order_placement.dart';
import '../../features/pos/services/discount_calculator.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/restaurant_table_isar.dart';
import '../local/mappers/order_mapper.dart';
import '../services/order_item_builder.dart';

class OrderPlacementException implements Exception {
  OrderPlacementException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlaceOrderInput {
  const PlaceOrderInput({
    required this.checkout,
    required this.cartItems,
    required this.discounts,
    required this.pricing,
    required this.paymentType,
    required this.isPrepaid,
    required this.createdByUserId,
    required this.deviceId,
    this.notes,
  });

  final PosCheckoutDraft checkout;
  final List<CartItem> cartItems;
  final List<AppliedDiscount> discounts;
  final CartPricingBreakdown pricing;
  final PaymentType paymentType;
  final bool isPrepaid;
  final String createdByUserId;
  final String deviceId;
  final String? notes;
}

class UpdateOrderInput {
  const UpdateOrderInput({
    required this.orderId,
    required this.checkout,
    required this.cartItems,
    required this.discounts,
    required this.pricing,
    required this.paymentType,
    required this.isPrepaid,
    required this.deviceId,
    this.notes,
  });

  final String orderId;
  final PosCheckoutDraft checkout;
  final List<CartItem> cartItems;
  final List<AppliedDiscount> discounts;
  final CartPricingBreakdown pricing;
  final PaymentType paymentType;
  final bool isPrepaid;
  final String deviceId;
  final String? notes;
}

class OrderRepository {
  OrderRepository(this._isar);

  final Isar _isar;

  Stream<List<Order>> watchAll() {
    return _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((records) => records.map(orderFromIsar).toList());
  }

  Future<Order?> findById(String id) async {
    final record =
        await _isar.orderIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return orderFromIsar(record);
  }

  Future<List<OrderItem>> findItemsByOrderId(String orderId) async {
    final records = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .orderIdEqualTo(orderId)
        .findAll();
    return records.map(orderItemFromIsar).toList();
  }

  Future<Order> placeOrder(PlaceOrderInput input) async {
    _validatePlacement(input.checkout, input.cartItems);

    final now = DateTime.now();
    final orderId = const Uuid().v4();
    final orderNumber = generateOrderNumber(deviceId: input.deviceId, now: now);
    final paymentStatus = resolvePaymentStatus(isPrepaid: input.isPrepaid);
    final discountSnapshot = wholeOrderDiscountSnapshot(input.discounts);

    final order = Order(
      id: orderId,
      orderNumber: orderNumber,
      orderType: input.checkout.orderType!,
      tableId: input.checkout.tableId,
      deliveryMode: input.checkout.deliveryMode,
      riderId: input.checkout.riderId,
      riderName: input.checkout.riderName,
      pickupCompanyId: input.checkout.pickupCompanyId,
      pickupCompanyName: input.checkout.pickupCompanyName,
      subtotal: input.pricing.subtotal,
      itemDiscountTotal: input.pricing.lineDiscountTotal,
      orderDiscountTotal: input.pricing.orderDiscountTotal,
      total: input.pricing.total,
      paymentType: input.paymentType,
      paymentStatus: paymentStatus,
      status: OrderStatus.received,
      isPrepaid: input.isPrepaid,
      isHeld: false,
      createdByUserId: input.createdByUserId,
      notes: input.notes,
      orderDiscountType: discountSnapshot?.type,
      orderDiscountValue: discountSnapshot?.value,
      orderDiscountReason: discountSnapshot?.reason,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      syncAction: SyncAction.create,
      deviceId: input.deviceId,
      version: 1,
    );

    final orderItems = buildOrderItems(
      orderId: orderId,
      cartItems: input.cartItems,
      discounts: input.discounts,
      pricing: input.pricing,
      deviceId: input.deviceId,
      now: now,
    );

    await _isar.writeTxn(() async {
      await _putOrderRecord(order, input.deviceId, isCreate: true);
      await _putOrderItems(orderItems, input.deviceId, isCreate: true);

      if (order.orderType == OrderType.dineIn && order.tableId != null) {
        await _occupyTable(
          tableId: order.tableId!,
          orderId: orderId,
          deviceId: input.deviceId,
        );
      }
    });

    return order;
  }

  Future<Order> updateOrderFromCart(UpdateOrderInput input) async {
    final existing = await findById(input.orderId);
    if (existing == null) {
      throw OrderPlacementException('Order not found');
    }

    if (existing.paymentStatus.isSettled) {
      throw OrderPlacementException(
        'Paid orders are read-only and cannot be edited',
      );
    }

    if (existing.status.isClosed) {
      throw OrderPlacementException('Closed orders cannot be edited');
    }

    if (input.cartItems.isEmpty) {
      throw OrderPlacementException('Cart is empty');
    }

    _validatePlacement(input.checkout, input.cartItems);

    final now = DateTime.now();
    final discountSnapshot = wholeOrderDiscountSnapshot(input.discounts);
    final updated = existing.copyWith(
      tableId: input.checkout.tableId,
      deliveryMode: input.checkout.deliveryMode,
      riderId: input.checkout.riderId,
      riderName: input.checkout.riderName,
      pickupCompanyId: input.checkout.pickupCompanyId,
      pickupCompanyName: input.checkout.pickupCompanyName,
      subtotal: input.pricing.subtotal,
      itemDiscountTotal: input.pricing.lineDiscountTotal,
      orderDiscountTotal: input.pricing.orderDiscountTotal,
      total: input.pricing.total,
      paymentType: input.paymentType,
      isPrepaid: input.isPrepaid,
      notes: input.notes,
      orderDiscountType: discountSnapshot?.type,
      orderDiscountValue: discountSnapshot?.value,
      orderDiscountReason: discountSnapshot?.reason,
      updatedAt: now,
    );

    final orderItems = buildOrderItems(
      orderId: input.orderId,
      cartItems: input.cartItems,
      discounts: input.discounts,
      pricing: input.pricing,
      deviceId: input.deviceId,
      now: now,
    );

    await _isar.writeTxn(() async {
      final oldItems = await _isar.orderItemIsars
          .filter()
          .orderIdEqualTo(input.orderId)
          .deletedAtIsNull()
          .findAll();

      for (final record in oldItems) {
        record.markDeleted(deviceId: input.deviceId);
        await _isar.orderItemIsars.put(record);
      }

      await _putOrderRecord(updated, input.deviceId, isCreate: false);
      await _putOrderItems(orderItems, input.deviceId, isCreate: true);
    });

    return updated;
  }

  Future<Order> advanceStatus({
    required String orderId,
    required OrderStatus targetStatus,
    required UserRole role,
    required String deviceId,
    PaymentType? paymentType,
  }) async {
    final order = await findById(orderId);
    if (order == null) {
      throw OrderLifecycleException('Order not found');
    }

    OrderLifecycle.validateTransition(
      order: order,
      target: targetStatus,
      role: role,
    );

    var updated = order.copyWith(status: targetStatus);

    if (targetStatus == OrderStatus.paid) {
      if (paymentType == null && order.paymentType == null) {
        throw OrderLifecycleException(
          'Select a payment type before marking this order paid',
        );
      }
      updated = updated.copyWith(
        paymentStatus: OrderPaymentStatus.paid,
        paymentType: paymentType ?? order.paymentType,
      );
    }

    await _isar.writeTxn(() async {
      final record = await _requireOrderRecord(orderId);
      applyOrderToIsar(
        record: record,
        order: updated,
        deviceId: deviceId,
        action: SyncAction.update,
      );
      await _isar.orderIsars.put(record);

      if (targetStatus == OrderStatus.completed) {
        await _releaseTableForOrder(
          tableId: updated.tableId,
          orderId: orderId,
          deviceId: deviceId,
        );
      }
    });

    return updated;
  }

  Future<Order> markPaid({
    required String orderId,
    required PaymentType paymentType,
    required UserRole role,
    required String deviceId,
  }) async {
    final order = await findById(orderId);
    if (order == null) {
      throw OrderLifecycleException('Order not found');
    }

    if (!OrderLifecycle.canMarkPaid(order, role)) {
      throw OrderLifecycleException('You cannot mark this order paid');
    }

    final updated = order.copyWith(
      paymentStatus: OrderPaymentStatus.paid,
      paymentType: paymentType,
      status: OrderStatus.paid,
    );

    await _isar.writeTxn(() async {
      final record = await _requireOrderRecord(orderId);
      applyOrderToIsar(
        record: record,
        order: updated,
        deviceId: deviceId,
        action: SyncAction.update,
      );
      await _isar.orderIsars.put(record);
    });

    return updated;
  }

  Future<Order> cancelOrder({
    required String orderId,
    required String reason,
    required UserRole role,
    required String deviceId,
    String? refundNote,
  }) async {
    final order = await findById(orderId);
    if (order == null) {
      throw OrderLifecycleException('Order not found');
    }

    if (!OrderLifecycle.canCancel(order, role)) {
      throw OrderLifecycleException('You cannot cancel this order');
    }

    if (reason.trim().isEmpty) {
      throw OrderLifecycleException('Cancellation reason is required');
    }

    final updated = order.copyWith(
      status: OrderStatus.cancelled,
      cancelReason: reason.trim(),
      cancelRefundNote: refundNote?.trim().isEmpty == true
          ? null
          : refundNote?.trim(),
    );

    await _isar.writeTxn(() async {
      final record = await _requireOrderRecord(orderId);
      applyOrderToIsar(
        record: record,
        order: updated,
        deviceId: deviceId,
        action: SyncAction.update,
      );
      await _isar.orderIsars.put(record);

      await _releaseTableForOrder(
        tableId: updated.tableId,
        orderId: orderId,
        deviceId: deviceId,
      );
    });

    return updated;
  }

  /// Sets the operational hold flag without changing status or totals.
  ///
  /// Hold is a visibility/priority flag only — it never affects financials,
  /// reporting totals, or lifecycle transitions.
  Future<Order> setHeld({
    required String orderId,
    required bool isHeld,
    required String deviceId,
  }) async {
    final order = await findById(orderId);
    if (order == null) {
      throw OrderLifecycleException('Order not found');
    }

    if (order.status.isClosed) {
      throw OrderLifecycleException('Closed orders cannot be held');
    }

    if (order.isHeld == isHeld) {
      return order;
    }

    final updated = order.copyWith(isHeld: isHeld);

    await _isar.writeTxn(() async {
      final record = await _requireOrderRecord(orderId);
      applyOrderToIsar(
        record: record,
        order: updated,
        deviceId: deviceId,
        action: SyncAction.update,
      );
      await _isar.orderIsars.put(record);
    });

    return updated;
  }

  void _validatePlacement(
    PosCheckoutDraft checkout,
    List<CartItem> cartItems,
  ) {
    if (cartItems.isEmpty) {
      throw OrderPlacementException('Cart is empty');
    }

    final orderType = checkout.orderType;
    if (orderType == null) {
      throw OrderPlacementException('Select an order type');
    }

    if (orderType == OrderType.dineIn && checkout.tableId == null) {
      throw OrderPlacementException('Select a table for dine-in orders');
    }

    if (orderType == OrderType.delivery) {
      final hasRider = checkout.riderId != null;
      final hasCompany = checkout.pickupCompanyId != null;
      if (!hasRider && !hasCompany) {
        throw OrderPlacementException(
          'Select a rider or pickup company for delivery',
        );
      }
    }
  }

  Future<void> _putOrderRecord(
    Order order,
    String deviceId, {
    required bool isCreate,
  }) async {
    final record = isCreate
        ? (OrderIsar()
          ..uuid = order.id
          ..createdAt = order.createdAt
          ..createdByUserId = order.createdByUserId
          ..isSynced = false
          ..syncAction = SyncAction.create.name
          ..deviceId = deviceId
          ..version = 1)
        : await _requireOrderRecord(order.id);

    applyOrderFieldsToIsar(record: record, order: order);
    if (!isCreate) {
      record.markUpdated(deviceId: deviceId, action: SyncAction.update);
    }
    await _isar.orderIsars.put(record);
  }

  Future<void> _putOrderItems(
    List<OrderItem> items,
    String deviceId, {
    required bool isCreate,
  }) async {
    for (final item in items) {
      await _isar.orderItemIsars.put(
        orderItemToIsar(
          item: item,
          deviceId: deviceId,
          action: isCreate ? SyncAction.create : SyncAction.update,
        ),
      );
    }
  }

  Future<OrderIsar> _requireOrderRecord(String orderId) async {
    final record =
        await _isar.orderIsars.filter().uuidEqualTo(orderId).findFirst();
    if (record == null || record.isDeleted) {
      throw OrderLifecycleException('Order not found');
    }
    return record;
  }

  Future<void> _occupyTable({
    required String tableId,
    required String orderId,
    required String deviceId,
  }) async {
    final tableRecord = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();

    if (tableRecord == null || tableRecord.isDeleted) {
      throw OrderPlacementException('Table not found');
    }

    if (tableRecord.statusEnum != TableStatus.available &&
        tableRecord.statusEnum != TableStatus.reserved) {
      throw OrderPlacementException('Table is not available');
    }

    tableRecord
      ..status = TableStatus.occupied.name
      ..currentOrderId = orderId
      ..markUpdated(deviceId: deviceId);

    await _isar.restaurantTableIsars.put(tableRecord);
  }

  Future<void> _releaseTableForOrder({
    required String? tableId,
    required String orderId,
    required String deviceId,
  }) async {
    if (tableId == null) return;

    final tableRecord = await _isar.restaurantTableIsars
        .filter()
        .uuidEqualTo(tableId)
        .findFirst();
    if (tableRecord == null || tableRecord.isDeleted) return;
    if (tableRecord.currentOrderId != orderId) return;

    tableRecord
      ..status = TableStatus.available.name
      ..currentOrderId = null
      ..markUpdated(deviceId: deviceId);

    await _isar.restaurantTableIsars.put(tableRecord);
  }
}
