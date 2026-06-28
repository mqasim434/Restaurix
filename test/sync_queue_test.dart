import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/core/sync/sync_queue.dart';
import 'package:restaurix/core/sync/sync_queue_models.dart';
import 'package:restaurix/data/local/collections/category_isar.dart';
import 'package:restaurix/data/local/collections/employee_isar.dart';
import 'package:restaurix/data/local/isar_service.dart';
import 'package:restaurix/domain/models/employee.dart';

void main() {
  late Directory tempDir;
  Isar? isar;
  SyncQueueService? service;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('restaurix_sync_test');
    isar = await Isar.open(
      IsarService.schemas,
      directory: tempDir.path,
      name: 'sync_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    service = SyncQueueService(isar!);
  });

  tearDown(() async {
    await isar?.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SyncQueueService', () {
    test('returns empty snapshot when everything is synced', () async {
      final snapshot = await service!.loadQueue();

      expect(snapshot.totalCount, 0);
      expect(snapshot.entries, isEmpty);
    });

    test('counts pending records across entity types', () async {
      await isar!.writeTxn(() async {
        await isar!.categoryIsars.put(
          CategoryIsar.create(
            name: 'Mains',
            deviceId: 'device-1',
            sortOrder: 0,
          ),
        );
        await isar!.employeeIsars.put(
          EmployeeIsar.create(
            fullName: 'Ali',
            role: 'Chef',
            hireDate: DateTime(2024, 1, 1),
            payType: EmployeePayType.hourly,
            deviceId: 'device-1',
          ),
        );
      });

      final snapshot = await service!.loadQueue();

      expect(snapshot.totalCount, 2);
      expect(snapshot.countsByType[SyncEntityType.category], 1);
      expect(snapshot.countsByType[SyncEntityType.employee], 1);
    });

    test('includes soft-deleted records with delete sync action', () async {
      late CategoryIsar record;
      await isar!.writeTxn(() async {
        record = CategoryIsar.create(
          name: 'Archived',
          deviceId: 'device-1',
          sortOrder: 0,
        );
        record.markDeleted(deviceId: 'device-1');
        await isar!.categoryIsars.put(record);
      });

      final snapshot = await service!.loadQueue();
      final entry = snapshot.entries.single;

      expect(entry.recordId, record.uuid);
      expect(entry.syncAction, SyncAction.delete);
      expect(entry.isSoftDeleted, isTrue);
    });

    test('excludes records marked synced', () async {
      await isar!.writeTxn(() async {
        final record = CategoryIsar.create(
          name: 'Synced',
          deviceId: 'device-1',
          sortOrder: 0,
        )..isSynced = true;
        await isar!.categoryIsars.put(record);
      });

      final snapshot = await service!.loadQueue();

      expect(snapshot.totalCount, 0);
    });

    test('multiple offline edits appear once with latest version', () async {
      late CategoryIsar record;
      await isar!.writeTxn(() async {
        record = CategoryIsar.create(
          name: 'Draft',
          deviceId: 'device-1',
          sortOrder: 0,
        );
        await isar!.categoryIsars.put(record);
      });

      await isar!.writeTxn(() async {
        record
          ..name = 'Draft v2'
          ..markUpdated(deviceId: 'device-1');
        await isar!.categoryIsars.put(record);
      });

      await isar!.writeTxn(() async {
        record
          ..name = 'Draft v3'
          ..markUpdated(deviceId: 'device-1');
        await isar!.categoryIsars.put(record);
      });

      final snapshot = await service!.loadQueue();

      expect(snapshot.totalCount, 1);
      expect(snapshot.entries.single.version, 3);
      expect(snapshot.entries.single.syncAction, SyncAction.update);
    });

    test('orders entries by updatedAt ascending', () async {
      final earlier = DateTime(2024, 6, 1, 10);
      final later = DateTime(2024, 6, 1, 12);

      await isar!.writeTxn(() async {
        final category = CategoryIsar.create(
          name: 'Later',
          deviceId: 'device-1',
          sortOrder: 0,
        )..updatedAt = later;
        await isar!.categoryIsars.put(category);

        final employee = EmployeeIsar.create(
          fullName: 'Earlier',
          role: 'Waiter',
          hireDate: DateTime(2024, 1, 1),
          payType: EmployeePayType.hourly,
          deviceId: 'device-1',
        )..updatedAt = earlier;
        await isar!.employeeIsars.put(employee);
      });

      final snapshot = await service!.loadQueue();

      expect(snapshot.entries, hasLength(2));
      expect(snapshot.entries.first.entityType, SyncEntityType.employee);
      expect(snapshot.entries.last.entityType, SyncEntityType.category);
    });
  });
}
