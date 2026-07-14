import 'dart:math';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/sync/sync_action.dart';
import '../../data/local/collections/attendance_record_isar.dart';
import '../../data/local/collections/category_isar.dart';
import '../../data/local/collections/employee_isar.dart';
import '../../data/local/collections/order_isar.dart';
import '../../data/local/collections/product_isar.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/order_enums.dart';
import '../../data/services/order_number_service.dart';

/// Generates a realistic local dataset for regression and performance testing
/// (Module 34). All seeded records are marked synced so they do not flood the
/// offline sync queue.
class DemoDataSeedResult {
  const DemoDataSeedResult({
    required this.categories,
    required this.products,
    required this.employees,
    required this.orders,
    required this.orderItems,
    required this.attendanceRecords,
    required this.elapsed,
  });

  final int categories;
  final int products;
  final int employees;
  final int orders;
  final int orderItems;
  final int attendanceRecords;
  final Duration elapsed;

  int get totalRecords =>
      categories + products + employees + orders + orderItems + attendanceRecords;
}

class DemoDataSeeder {
  DemoDataSeeder({
    required Isar isar,
    required String deviceId,
    Random? random,
    this.orderDays = 90,
    this.ordersPerDay = 20,
    this.productsPerCategory = 15,
    this.employeeCount = 25,
  })  : _isar = isar,
        _deviceId = deviceId,
        _random = random ?? Random(34);

  final Isar _isar;
  final String _deviceId;
  final Random _random;
  final int orderDays;
  final int ordersPerDay;
  final int productsPerCategory;
  final int employeeCount;

  static const _categoryNames = [
    'Appetizers',
    'Soups & Salads',
    'Burgers',
    'Pizza',
    'Pasta',
    'Grill',
    'Desserts',
    'Beverages',
  ];

  Future<DemoDataSeedResult> seed({DateTime? now}) async {
    final started = DateTime.now();
    final anchor = now ?? DateTime.now();

    final categoryRecords = <CategoryIsar>[];
    for (var i = 0; i < _categoryNames.length; i++) {
      categoryRecords.add(
        CategoryIsar.create(
          name: _categoryNames[i],
          deviceId: _deviceId,
          sortOrder: i,
        )..isSynced = true,
      );
    }

    final productRecords = <ProductIsar>[];
    for (final category in categoryRecords) {
      for (var i = 0; i < productsPerCategory; i++) {
        productRecords.add(
          ProductIsar.create(
            name: '${category.name} Item ${i + 1}',
            categoryId: category.uuid,
            basePrice: 4.5 + _random.nextDouble() * 24,
            deviceId: _deviceId,
            kitchenCategory: category.name,
            estimatedPrepMinutes:
                AppConstants.defaultProductPrepMinutes + _random.nextInt(8),
          )..isSynced = true,
        );
      }
    }

    final employeeRecords = <EmployeeIsar>[];
    for (var i = 0; i < employeeCount; i++) {
      final hourly = i.isEven;
      employeeRecords.add(
        EmployeeIsar.create(
          fullName: 'Demo Staff ${i + 1}',
          role: i.isEven ? 'Waiter' : 'Chef',
          hireDate: anchor.subtract(Duration(days: 120 + i * 3)),
          payType: hourly ? EmployeePayType.hourly : EmployeePayType.monthly,
          deviceId: _deviceId,
          hourlyRate: hourly ? 12 + _random.nextDouble() * 6 : null,
          monthlySalaryBase: hourly ? null : 1800 + _random.nextDouble() * 800,
        )..isSynced = true,
      );
    }

    final orderRecords = <OrderIsar>[];
    final orderItemRecords = <OrderItemIsar>[];
    final adminUserId = 'demo-admin';
    final dailyOrderCounters = <String, int>{};

    for (var day = 0; day < orderDays; day++) {
      final dayStart = DateTime(
        anchor.year,
        anchor.month,
        anchor.day,
      ).subtract(Duration(days: orderDays - day));

      for (var o = 0; o < ordersPerDay; o++) {
        final createdAt = dayStart.add(
          Duration(
            hours: 10 + _random.nextInt(12),
            minutes: _random.nextInt(60),
          ),
        );

        final roll = _random.nextDouble();
        final (status, paymentStatus, isPrepaid) = _resolveStatuses(roll);

        final itemCount = 1 + _random.nextInt(4);
        var subtotal = 0.0;
        final itemsForOrder = <OrderItemIsar>[];

        for (var itemIndex = 0; itemIndex < itemCount; itemIndex++) {
          final product =
              productRecords[_random.nextInt(productRecords.length)];
          final quantity = 1 + _random.nextInt(3);
          final lineTotal = product.basePrice * quantity;
          subtotal += lineTotal;

          final receivedAt = createdAt.add(const Duration(minutes: 2));
          final readyAt = receivedAt.add(
            Duration(minutes: product.estimatedPrepMinutes),
          );

          itemsForOrder.add(
            OrderItemIsar()
              ..uuid = const Uuid().v4()
              ..orderId = '' // filled after order uuid assigned
              ..productId = product.uuid
              ..name = product.name
              ..unitPrice = product.basePrice
              ..quantity = quantity
              ..lineTotal = lineTotal
              ..kitchenStatus = _kitchenStatusForOrder(status).name
              ..prepMinutes = product.estimatedPrepMinutes
              ..kitchenStatusChangedAt = readyAt
              ..kitchenReceivedAt = receivedAt
              ..kitchenReadyAt =
                  status == OrderStatus.cancelled ? null : readyAt
              ..createdAt = createdAt
              ..updatedAt = readyAt
              ..isSynced = true
              ..syncAction = SyncAction.create.name
              ..deviceId = _deviceId
              ..version = 1,
          );
        }

        final orderType = _randomOrderType();
        final dateKey =
            '${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
        final dailySeq = (dailyOrderCounters[dateKey] ?? 0) + 1;
        dailyOrderCounters[dateKey] = dailySeq;

        final order = OrderIsar()
          ..uuid = const Uuid().v4()
          ..orderNumber = formatDailyOrderNumber(createdAt, dailySeq)
          ..orderType = orderType.wireValue
          ..subtotal = subtotal
          ..itemDiscountTotal = 0
          ..orderDiscountTotal = 0
          ..total = subtotal
          ..paymentType = _randomPaymentType().name
          ..paymentStatus = paymentStatus.name
          ..status = status.name
          ..isPrepaid = isPrepaid
          ..isHeld = false
          ..createdByUserId = adminUserId
          ..createdAt = createdAt
          ..updatedAt = createdAt.add(Duration(minutes: 5 + _random.nextInt(40)))
          ..isSynced = true
          ..syncAction = SyncAction.create.name
          ..deviceId = _deviceId
          ..version = 1;

        for (final item in itemsForOrder) {
          item.orderId = order.uuid;
        }

        orderRecords.add(order);
        orderItemRecords.addAll(itemsForOrder);
      }
    }

    final attendanceRecords = <AttendanceRecordIsar>[];
    for (var day = 0; day < 30; day++) {
      final dayDate = anchor.subtract(Duration(days: day));
      final sample = employeeRecords.take(8 + _random.nextInt(6));
      for (final employee in sample) {
        final checkIn = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          8 + _random.nextInt(2),
          _random.nextInt(30),
        );
        final checkOut = checkIn.add(Duration(hours: 7 + _random.nextInt(3)));
        attendanceRecords.add(
          AttendanceRecordIsar.create(
            employeeId: employee.uuid,
            checkInTime: checkIn,
            source: AttendanceSource.fingerprint,
            deviceId: _deviceId,
            createdByUserId: adminUserId,
          )
            ..checkOutTime = checkOut
            ..updatedAt = checkOut
            ..isSynced = true,
        );
      }
    }

    await _isar.writeTxn(() async {
      await _isar.categoryIsars.putAll(categoryRecords);
      await _isar.productIsars.putAll(productRecords);
      await _isar.employeeIsars.putAll(employeeRecords);

      const batchSize = 500;
      for (var i = 0; i < orderRecords.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, orderRecords.length);
        await _isar.orderIsars.putAll(orderRecords.sublist(i, end));
      }
      for (var i = 0; i < orderItemRecords.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, orderItemRecords.length);
        await _isar.orderItemIsars.putAll(orderItemRecords.sublist(i, end));
      }
      await _isar.attendanceRecordIsars.putAll(attendanceRecords);
    });

    return DemoDataSeedResult(
      categories: categoryRecords.length,
      products: productRecords.length,
      employees: employeeRecords.length,
      orders: orderRecords.length,
      orderItems: orderItemRecords.length,
      attendanceRecords: attendanceRecords.length,
      elapsed: DateTime.now().difference(started),
    );
  }

  (OrderStatus status, OrderPaymentStatus paymentStatus, bool isPrepaid)
      _resolveStatuses(double roll) {
    if (roll < 0.08) {
      return (
        OrderStatus.cancelled,
        OrderPaymentStatus.unpaid,
        false,
      );
    }
    if (roll < 0.73) {
      return (
        OrderStatus.paid,
        OrderPaymentStatus.paid,
        true,
      );
    }
    if (roll < 0.83) {
      return (
        OrderStatus.preparing,
        OrderPaymentStatus.unpaid,
        false,
      );
    }
    if (roll < 0.91) {
      return (
        OrderStatus.ready,
        OrderPaymentStatus.unpaid,
        false,
      );
    }
    return (
      OrderStatus.served,
      OrderPaymentStatus.unpaid,
      false,
    );
  }

  KitchenStatus _kitchenStatusForOrder(OrderStatus status) {
    return switch (status) {
      OrderStatus.preparing => KitchenStatus.preparing,
      OrderStatus.ready => KitchenStatus.ready,
      OrderStatus.served => KitchenStatus.served,
      OrderStatus.paid || OrderStatus.completed => KitchenStatus.served,
      OrderStatus.cancelled => KitchenStatus.received,
      _ => KitchenStatus.received,
    };
  }

  OrderType _randomOrderType() {
    final roll = _random.nextDouble();
    if (roll < 0.55) return OrderType.dineIn;
    if (roll < 0.8) return OrderType.takeaway;
    return OrderType.delivery;
  }

  PaymentType _randomPaymentType() {
    final roll = _random.nextDouble();
    if (roll < 0.5) return PaymentType.cash;
    if (roll < 0.85) return PaymentType.card;
    return PaymentType.online;
  }
}
