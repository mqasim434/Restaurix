import 'dart:async';

import 'package:isar/isar.dart';

import '../../data/local/collections/attendance_record_isar.dart';
import '../../data/local/collections/category_isar.dart';
import '../../data/local/collections/deal_isar.dart';
import '../../data/local/collections/deal_item_isar.dart';
import '../../data/local/collections/draft_order_isar.dart';
import '../../data/local/collections/employee_isar.dart';
import '../../data/local/collections/hall_isar.dart';
import '../../data/local/collections/order_isar.dart';
import '../../data/local/collections/pickup_company_isar.dart';
import '../../data/local/collections/product_isar.dart';
import '../../data/local/collections/product_variant_isar.dart';
import '../../data/local/collections/restaurant_table_isar.dart';
import '../../data/local/collections/rider_isar.dart';
import '../../data/local/collections/salary_slip_isar.dart';
import 'sync_action.dart';
import 'sync_queue_models.dart';

/// Identifies every locally modified record that still needs remote sync.
///
/// Upload/download is handled in Module 31; this service only reports queue state.
class SyncQueueService {
  SyncQueueService(this._isar);

  final Isar _isar;

  Stream<SyncQueueSnapshot> watchQueue() {
    return _watchAnySyncableChange().asyncMap((_) => loadQueue());
  }

  Future<SyncQueueSnapshot> loadQueue() async {
    final entries = <SyncQueueEntry>[
      ...await _entriesForCategories(),
      ...await _entriesForProducts(),
      ...await _entriesForProductVariants(),
      ...await _entriesForDeals(),
      ...await _entriesForDealItems(),
      ...await _entriesForHalls(),
      ...await _entriesForRestaurantTables(),
      ...await _entriesForOrders(),
      ...await _entriesForOrderItems(),
      ...await _entriesForDraftOrders(),
      ...await _entriesForRiders(),
      ...await _entriesForPickupCompanies(),
      ...await _entriesForEmployees(),
      ...await _entriesForAttendanceRecords(),
      ...await _entriesForSalarySlips(),
    ]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    final countsByType = <SyncEntityType, int>{};
    for (final entry in entries) {
      countsByType.update(
        entry.entityType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return SyncQueueSnapshot(
      entries: entries,
      countsByType: countsByType,
      totalCount: entries.length,
    );
  }

  Stream<void> _watchAnySyncableChange() {
    final controller = StreamController<void>.broadcast();
    final subscriptions = <StreamSubscription<dynamic>>[];

    void emit() {
      if (!controller.isClosed) controller.add(null);
    }

    void watch<T>(Stream<T> stream) {
      subscriptions.add(stream.listen((_) => emit()));
    }

    watch(_isar.categoryIsars.watchLazy(fireImmediately: true));
    watch(_isar.productIsars.watchLazy(fireImmediately: true));
    watch(_isar.productVariantIsars.watchLazy(fireImmediately: true));
    watch(_isar.dealIsars.watchLazy(fireImmediately: true));
    watch(_isar.dealItemIsars.watchLazy(fireImmediately: true));
    watch(_isar.hallIsars.watchLazy(fireImmediately: true));
    watch(_isar.restaurantTableIsars.watchLazy(fireImmediately: true));
    watch(_isar.orderIsars.watchLazy(fireImmediately: true));
    watch(_isar.orderItemIsars.watchLazy(fireImmediately: true));
    watch(_isar.draftOrderIsars.watchLazy(fireImmediately: true));
    watch(_isar.riderIsars.watchLazy(fireImmediately: true));
    watch(_isar.pickupCompanyIsars.watchLazy(fireImmediately: true));
    watch(_isar.employeeIsars.watchLazy(fireImmediately: true));
    watch(_isar.attendanceRecordIsars.watchLazy(fireImmediately: true));
    watch(_isar.salarySlipIsars.watchLazy(fireImmediately: true));

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Future<List<SyncQueueEntry>> _entriesForCategories() async {
    final records = await _isar.categoryIsars
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.category,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForProducts() async {
    final records =
        await _isar.productIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.product,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForProductVariants() async {
    final records = await _isar.productVariantIsars
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.productVariant,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForDeals() async {
    final records =
        await _isar.dealIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.deal,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForDealItems() async {
    final records =
        await _isar.dealItemIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.dealItem,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForHalls() async {
    final records =
        await _isar.hallIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.hall,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForRestaurantTables() async {
    final records = await _isar.restaurantTableIsars
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.restaurantTable,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForOrders() async {
    final records =
        await _isar.orderIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.order,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForOrderItems() async {
    final records =
        await _isar.orderItemIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.orderItem,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForDraftOrders() async {
    final records =
        await _isar.draftOrderIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.draftOrder,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForRiders() async {
    final records =
        await _isar.riderIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.rider,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForPickupCompanies() async {
    final records = await _isar.pickupCompanyIsars
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.pickupCompany,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForEmployees() async {
    final records =
        await _isar.employeeIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.employee,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForAttendanceRecords() async {
    final records = await _isar.attendanceRecordIsars
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.attendanceRecord,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  Future<List<SyncQueueEntry>> _entriesForSalarySlips() async {
    final records =
        await _isar.salarySlipIsars.filter().isSyncedEqualTo(false).findAll();
    return [
      for (final record in records)
        _entry(
          entityType: SyncEntityType.salarySlip,
          recordId: record.uuid,
          syncAction: record.syncActionEnum,
          updatedAt: record.updatedAt,
          deletedAt: record.deletedAt,
          version: record.version,
        ),
    ];
  }

  SyncQueueEntry _entry({
    required SyncEntityType entityType,
    required String recordId,
    required SyncAction syncAction,
    required DateTime updatedAt,
    required DateTime? deletedAt,
    required int version,
  }) {
    return SyncQueueEntry(
      entityType: entityType,
      recordId: recordId,
      syncAction: syncAction,
      updatedAt: updatedAt,
      isSoftDeleted: deletedAt != null,
      version: version,
    );
  }
}
