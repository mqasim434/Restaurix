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
    if (input.cartItems.isEmpty) {
      throw OrderPlacementException('Cart is empty');
    }

    final orderType = input.checkout.orderType;
    if (orderType == null) {
      throw OrderPlacementException('Select an order type');
    }

    if (orderType == OrderType.dineIn && input.checkout.tableId == null) {
      throw OrderPlacementException('Select a table for dine-in orders');
    }

    if (orderType == OrderType.delivery) {
      final hasRider = input.checkout.riderId != null;
      final hasCompany = input.checkout.pickupCompanyId != null;
      if (!hasRider && !hasCompany) {
        throw OrderPlacementException(
          'Select a rider or pickup company for delivery',
        );
      }
    }

    final now = DateTime.now();
    final orderId = const Uuid().v4();
    final orderNumber = generateOrderNumber(deviceId: input.deviceId, now: now);
    final paymentStatus = resolvePaymentStatus(isPrepaid: input.isPrepaid);

    final order = Order(
      id: orderId,
      orderNumber: orderNumber,
      orderType: orderType,
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
      createdByUserId: input.createdByUserId,
      notes: input.notes,
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
      final orderRecord = OrderIsar()
        ..uuid = order.id
        ..orderNumber = order.orderNumber
        ..orderType = order.orderType.wireValue
        ..tableId = order.tableId
        ..deliveryMode = order.deliveryMode?.wireValue
        ..riderId = order.riderId
        ..riderName = order.riderName
        ..pickupCompanyId = order.pickupCompanyId
        ..pickupCompanyName = order.pickupCompanyName
        ..subtotal = order.subtotal
        ..itemDiscountTotal = order.itemDiscountTotal
        ..orderDiscountTotal = order.orderDiscountTotal
        ..total = order.total
        ..paymentType = order.paymentType?.name
        ..paymentStatus = order.paymentStatus.name
        ..status = order.status.name
        ..isPrepaid = order.isPrepaid
        ..createdByUserId = order.createdByUserId
        ..notes = order.notes
        ..createdAt = order.createdAt
        ..updatedAt = order.updatedAt
        ..isSynced = false
        ..syncAction = SyncAction.create.name
        ..deviceId = input.deviceId
        ..version = 1;

      await _isar.orderIsars.put(orderRecord);

      for (final item in orderItems) {
        await _isar.orderItemIsars.put(
          orderItemToIsar(
            item: item,
            deviceId: input.deviceId,
            action: SyncAction.create,
          ),
        );
      }

      if (orderType == OrderType.dineIn && order.tableId != null) {
        final tableRecord = await _isar.restaurantTableIsars
            .filter()
            .uuidEqualTo(order.tableId!)
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
          ..markUpdated(deviceId: input.deviceId);

        await _isar.restaurantTableIsars.put(tableRecord);
      }
    });

    return order;
  }
}
