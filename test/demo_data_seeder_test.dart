import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:restaurix/core/debug/demo_data_seeder.dart';
import 'package:restaurix/data/local/collections/order_isar.dart';
import 'package:restaurix/data/local/collections/product_isar.dart';
import 'package:restaurix/data/local/isar_service.dart';

void main() {
  late Directory tempDir;
  Isar? isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('restaurix_demo_seed_test');
    isar = await Isar.open(
      IsarService.schemas,
      directory: tempDir.path,
      name: 'demo_seed_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar?.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seeds realistic volume for regression testing', () async {
    final seeder = DemoDataSeeder(
      isar: isar!,
      deviceId: 'demo-device',
      orderDays: 7,
      ordersPerDay: 10,
      productsPerCategory: 5,
      employeeCount: 5,
    );

    final result = await seeder.seed(now: DateTime(2024, 6, 15, 12));

    expect(result.categories, 8);
    expect(result.products, 40);
    expect(result.employees, 5);
    expect(result.orders, 70);
    expect(result.orderItems, greaterThan(70));
    expect(result.attendanceRecords, greaterThan(0));
    expect(result.elapsed.inSeconds, lessThan(30));

    final db = isar!;
    final orderCount = await db.orderIsars.count();
    final productCount = await db.productIsars.count();
    expect(orderCount, 70);
    expect(productCount, 40);

    final unsyncedOrders =
        await db.orderIsars.filter().isSyncedEqualTo(false).count();
    expect(unsyncedOrders, 0);
  });
}
