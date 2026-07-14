import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/data/local/collections/order_isar.dart';
import 'package:restaurix/data/local/isar_service.dart';
import 'package:restaurix/data/services/order_number_service.dart';
import 'package:restaurix/domain/models/order_enums.dart';

void main() {
  late Directory tempDir;
  Isar? isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('restaurix_order_no_test');
    isar = await Isar.open(
      IsarService.schemas,
      directory: tempDir.path,
      name: 'order_no_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar?.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('formatDailyOrderNumber', () {
    test('formats ORD-date-sequence with zero padding', () {
      expect(
        formatDailyOrderNumber(DateTime(2026, 6, 30), 2),
        'ORD-20260630-002',
      );
      expect(
        formatDailyOrderNumber(DateTime(2026, 1, 5), 1),
        'ORD-20260105-001',
      );
    });
  });

  group('tablet / customer order numbers', () {
    test('formats ODR / ODRM daily sequences', () {
      expect(formatTabletDailyOrderNumber(1), 'ODR-0001');
      expect(formatTabletDailyOrderNumber(12), 'ODR-0012');
      expect(formatCustomerDailyOrderNumber(1), 'ODRM-0001');
      expect(formatCustomerDailyOrderNumber(99), 'ODRM-0099');
    });

    test('detects tablet vs customer prefixes without confusing ODR and ODRM', () {
      expect(isTabletOrderNumber('ODR-0001'), isTrue);
      expect(isMobileOrderNumber('ODR-0001'), isTrue);
      expect(isCustomerAppOrderNumber('ODR-0001'), isFalse);

      expect(isCustomerAppOrderNumber('ODRM-0001'), isTrue);
      expect(isTabletOrderNumber('ODRM-0001'), isFalse);
      expect(isMobileOrderNumber('ODRM-0001'), isFalse);

      expect(isTabletOrderNumber('ORDM-20260630-001'), isTrue);
      expect(isCustomerAppOrderNumber('ORDC-20260630-001'), isTrue);
      expect(isTabletOrderNumber('ORD-20260630-001'), isFalse);
    });

    test('allocateNextTabletOrderNumberInTxn resets daily', () async {
      final day = DateTime(2026, 6, 30, 12);
      await isar!.writeTxn(() async {
        final first = await allocateNextTabletOrderNumberInTxn(isar!, now: day);
        await isar!.orderIsars.put(_order(first, day, id: 't1'));
        final second = await allocateNextTabletOrderNumberInTxn(isar!, now: day);
        expect(first, 'ODR-0001');
        expect(second, 'ODR-0002');
      });

      final nextDay = DateTime(2026, 7, 1, 9);
      await isar!.writeTxn(() async {
        final reset =
            await allocateNextTabletOrderNumberInTxn(isar!, now: nextDay);
        expect(reset, 'ODR-0001');
      });
    });

    test('allocateNextCustomerOrderNumberInTxn increments ODRM', () async {
      final day = DateTime(2026, 6, 30, 12);
      await isar!.writeTxn(() async {
        final first =
            await allocateNextCustomerOrderNumberInTxn(isar!, now: day);
        await isar!.orderIsars.put(_order(first, day, id: 'c1'));
        final second =
            await allocateNextCustomerOrderNumberInTxn(isar!, now: day);
        expect(first, 'ODRM-0001');
        expect(second, 'ODRM-0002');
      });
    });
  });

  group('allocateNextOrderNumberInTxn', () {
    test('starts at 001 for a new day', () async {
      await isar!.writeTxn(() async {
        final number = await allocateNextOrderNumberInTxn(
          isar!,
          now: DateTime(2026, 6, 30, 12),
        );
        expect(number, 'ORD-20260630-001');
      });
    });

    test('increments within the same local day', () async {
      final day = DateTime(2026, 6, 30, 12);

      await isar!.writeTxn(() async {
        final first = await allocateNextOrderNumberInTxn(isar!, now: day);
        await isar!.orderIsars.put(_order(first, day, id: 'order-1'));
        final second = await allocateNextOrderNumberInTxn(isar!, now: day);
        expect(first, 'ORD-20260630-001');
        expect(second, 'ORD-20260630-002');
      });
    });

    test('resets sequence on a new calendar day', () async {
      final dayOne = DateTime(2026, 6, 30, 23);
      final dayTwo = DateTime(2026, 7, 1, 1);

      await isar!.writeTxn(() async {
        final first = await allocateNextOrderNumberInTxn(isar!, now: dayOne);
        await isar!.orderIsars.put(_order(first, dayOne, id: 'order-1'));
      });

      await isar!.writeTxn(() async {
        final nextDay = await allocateNextOrderNumberInTxn(isar!, now: dayTwo);
        expect(nextDay, 'ORD-20260701-001');
      });
    });

    test('ignores soft-deleted orders when counting', () async {
      final day = DateTime(2026, 6, 30, 12);
      final deleted = _order('ORD-20260630-001', day, id: 'deleted-order')
        ..deletedAt = day;

      await isar!.writeTxn(() async {
        await isar!.orderIsars.put(deleted);
        final next = await allocateNextOrderNumberInTxn(isar!, now: day);
        expect(next, 'ORD-20260630-001');
      });
    });
  });
}

OrderIsar _order(String orderNumber, DateTime day, {required String id}) {
  return OrderIsar()
    ..uuid = id
    ..orderNumber = orderNumber
    ..orderType = OrderType.dineIn.wireValue
    ..subtotal = 0
    ..itemDiscountTotal = 0
    ..orderDiscountTotal = 0
    ..total = 0
    ..paymentStatus = OrderPaymentStatus.unpaid.name
    ..status = OrderStatus.received.name
    ..createdByUserId = 'admin'
    ..createdAt = day
    ..updatedAt = day
    ..isSynced = true
    ..syncAction = SyncAction.create.name
    ..deviceId = 'device'
    ..version = 1;
}
