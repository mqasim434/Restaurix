import 'package:isar/isar.dart';

import '../remote/supabase_table_names.dart';
import '../../data/local/collections/attendance_record_isar.dart';
import '../../data/local/collections/category_isar.dart';
import '../../data/local/collections/deal_isar.dart';
import '../../data/local/collections/deal_item_isar.dart';
import '../../data/local/collections/employee_isar.dart';
import '../../data/local/collections/hall_isar.dart';
import '../../data/local/collections/item_modifier_isar.dart';
import '../../data/local/collections/modifier_group_isar.dart';
import '../../data/local/collections/order_isar.dart';
import '../../data/local/collections/pickup_company_isar.dart';
import '../../data/local/collections/product_isar.dart';
import '../../data/local/collections/product_variant_isar.dart';
import '../../data/local/collections/restaurant_table_isar.dart';
import '../../data/local/collections/rider_isar.dart';
import '../../data/local/collections/salary_slip_isar.dart';
import 'sync_entity_handler.dart';
import 'sync_handler_runner.dart';
import 'sync_queue_models.dart';

import 'sync_remote_mappers.dart';

List<SyncEntityHandler> buildSyncEntityHandlers() {
  return [
    CategorySyncHandler(),
    ModifierGroupSyncHandler(),
    ProductSyncHandler(),
    ProductVariantSyncHandler(),
    ItemModifierSyncHandler(),
    DealSyncHandler(),
    DealItemSyncHandler(),
    HallSyncHandler(),
    RestaurantTableSyncHandler(),
    RiderSyncHandler(),
    PickupCompanySyncHandler(),
    EmployeeSyncHandler(),
    OrderSyncHandler(),
    OrderItemSyncHandler(),
    AttendanceRecordSyncHandler(),
    SalarySlipSyncHandler(),
  ]..sort((a, b) => a.priority.compareTo(b.priority));
}

abstract class _CollectionHandler<R> implements SyncEntityHandler {
  Future<List<R>> findUnsynced(Isar isar);
  Future<R?> findLocalById(Isar isar, String id);
  Future<void> putLocal(Isar isar, R record);
  Map<String, dynamic> toRemote(R record);
  Future<void> writeRemoteToLocal(Isar isar, Map<String, dynamic> remote);
  String recordId(R record);
  int versionOf(R record) => (record as dynamic).version as int;
  DateTime updatedAtOf(R record) => (record as dynamic).updatedAt as DateTime;
  bool isDeleteOf(R record) => (record as dynamic).deletedAt != null;
  Map<String, dynamic> localSnapshot(R record) => toRemote(record);

  @override
  Future<EntitySyncResult> sync(SyncEntityContext context) {
    return runCollectionSync<R>(
      context: context,
      entityType: entityType,
      tableName: tableName,
      findUnsynced: findUnsynced,
      toRemote: toRemote,
      findLocalById: findLocalById,
      putLocal: putLocal,
      writeRemoteToLocal: writeRemoteToLocal,
      recordId: recordId,
      versionOf: versionOf,
      updatedAtOf: updatedAtOf,
      isDeleteOf: isDeleteOf,
      localSnapshot: localSnapshot,
    );
  }
}

class CategorySyncHandler extends _CollectionHandler<CategoryIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.category;

  @override
  String get tableName => SupabaseTableNames.categories;

  @override
  int get priority => 10;

  @override
  Future<List<CategoryIsar>> findUnsynced(Isar isar) =>
      isar.categoryIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<CategoryIsar?> findLocalById(Isar isar, String id) =>
      isar.categoryIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, CategoryIsar record) =>
      isar.categoryIsars.put(record);

  @override
  String recordId(CategoryIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(CategoryIsar record) =>
      CategoryRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      CategoryRemoteMapper.applyRemote(isar, remote);
}

class ModifierGroupSyncHandler extends _CollectionHandler<ModifierGroupIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.modifierGroup;

  @override
  String get tableName => SupabaseTableNames.modifierGroups;

  @override
  int get priority => 20;

  @override
  Future<List<ModifierGroupIsar>> findUnsynced(Isar isar) =>
      isar.modifierGroupIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<ModifierGroupIsar?> findLocalById(Isar isar, String id) =>
      isar.modifierGroupIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, ModifierGroupIsar record) =>
      isar.modifierGroupIsars.put(record);

  @override
  String recordId(ModifierGroupIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(ModifierGroupIsar record) =>
      ModifierGroupRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      ModifierGroupRemoteMapper.applyRemote(isar, remote);
}

class ProductSyncHandler extends _CollectionHandler<ProductIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.product;

  @override
  String get tableName => SupabaseTableNames.products;

  @override
  int get priority => 30;

  @override
  Future<List<ProductIsar>> findUnsynced(Isar isar) =>
      isar.productIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<ProductIsar?> findLocalById(Isar isar, String id) =>
      isar.productIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, ProductIsar record) =>
      isar.productIsars.put(record);

  @override
  String recordId(ProductIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(ProductIsar record) =>
      ProductRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      ProductRemoteMapper.applyRemote(isar, remote);
}

class ProductVariantSyncHandler extends _CollectionHandler<ProductVariantIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.productVariant;

  @override
  String get tableName => SupabaseTableNames.productVariants;

  @override
  int get priority => 40;

  @override
  Future<List<ProductVariantIsar>> findUnsynced(Isar isar) =>
      isar.productVariantIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<ProductVariantIsar?> findLocalById(Isar isar, String id) =>
      isar.productVariantIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, ProductVariantIsar record) =>
      isar.productVariantIsars.put(record);

  @override
  String recordId(ProductVariantIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(ProductVariantIsar record) =>
      ProductVariantRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      ProductVariantRemoteMapper.applyRemote(isar, remote);
}

class ItemModifierSyncHandler extends _CollectionHandler<ItemModifierIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.modifier;

  @override
  String get tableName => SupabaseTableNames.modifiers;

  @override
  int get priority => 50;

  @override
  Future<List<ItemModifierIsar>> findUnsynced(Isar isar) =>
      isar.itemModifierIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<ItemModifierIsar?> findLocalById(Isar isar, String id) =>
      isar.itemModifierIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, ItemModifierIsar record) =>
      isar.itemModifierIsars.put(record);

  @override
  String recordId(ItemModifierIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(ItemModifierIsar record) =>
      ItemModifierRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      ItemModifierRemoteMapper.applyRemote(isar, remote);
}

class DealSyncHandler extends _CollectionHandler<DealIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.deal;

  @override
  String get tableName => SupabaseTableNames.deals;

  @override
  int get priority => 60;

  @override
  Future<List<DealIsar>> findUnsynced(Isar isar) =>
      isar.dealIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<DealIsar?> findLocalById(Isar isar, String id) =>
      isar.dealIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, DealIsar record) => isar.dealIsars.put(record);

  @override
  String recordId(DealIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(DealIsar record) =>
      DealRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      DealRemoteMapper.applyRemote(isar, remote);
}

class DealItemSyncHandler extends _CollectionHandler<DealItemIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.dealItem;

  @override
  String get tableName => SupabaseTableNames.dealItems;

  @override
  int get priority => 70;

  @override
  Future<List<DealItemIsar>> findUnsynced(Isar isar) =>
      isar.dealItemIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<DealItemIsar?> findLocalById(Isar isar, String id) =>
      isar.dealItemIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, DealItemIsar record) =>
      isar.dealItemIsars.put(record);

  @override
  String recordId(DealItemIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(DealItemIsar record) =>
      DealItemRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      DealItemRemoteMapper.applyRemote(isar, remote);
}

class HallSyncHandler extends _CollectionHandler<HallIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.hall;

  @override
  String get tableName => SupabaseTableNames.halls;

  @override
  int get priority => 80;

  @override
  Future<List<HallIsar>> findUnsynced(Isar isar) =>
      isar.hallIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<HallIsar?> findLocalById(Isar isar, String id) =>
      isar.hallIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, HallIsar record) => isar.hallIsars.put(record);

  @override
  String recordId(HallIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(HallIsar record) => HallRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      HallRemoteMapper.applyRemote(isar, remote);
}

class RestaurantTableSyncHandler extends _CollectionHandler<RestaurantTableIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.restaurantTable;

  @override
  String get tableName => SupabaseTableNames.restaurantTables;

  @override
  int get priority => 90;

  @override
  Future<List<RestaurantTableIsar>> findUnsynced(Isar isar) =>
      isar.restaurantTableIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<RestaurantTableIsar?> findLocalById(Isar isar, String id) =>
      isar.restaurantTableIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, RestaurantTableIsar record) =>
      isar.restaurantTableIsars.put(record);

  @override
  String recordId(RestaurantTableIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(RestaurantTableIsar record) =>
      RestaurantTableRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      RestaurantTableRemoteMapper.applyRemote(isar, remote);
}

class RiderSyncHandler extends _CollectionHandler<RiderIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.rider;

  @override
  String get tableName => SupabaseTableNames.riders;

  @override
  int get priority => 100;

  @override
  Future<List<RiderIsar>> findUnsynced(Isar isar) =>
      isar.riderIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<RiderIsar?> findLocalById(Isar isar, String id) =>
      isar.riderIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, RiderIsar record) => isar.riderIsars.put(record);

  @override
  String recordId(RiderIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(RiderIsar record) => RiderRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      RiderRemoteMapper.applyRemote(isar, remote);
}

class PickupCompanySyncHandler extends _CollectionHandler<PickupCompanyIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.pickupCompany;

  @override
  String get tableName => SupabaseTableNames.pickupCompanies;

  @override
  int get priority => 110;

  @override
  Future<List<PickupCompanyIsar>> findUnsynced(Isar isar) =>
      isar.pickupCompanyIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<PickupCompanyIsar?> findLocalById(Isar isar, String id) =>
      isar.pickupCompanyIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, PickupCompanyIsar record) =>
      isar.pickupCompanyIsars.put(record);

  @override
  String recordId(PickupCompanyIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(PickupCompanyIsar record) =>
      PickupCompanyRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      PickupCompanyRemoteMapper.applyRemote(isar, remote);
}

class EmployeeSyncHandler extends _CollectionHandler<EmployeeIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.employee;

  @override
  String get tableName => SupabaseTableNames.employees;

  @override
  int get priority => 120;

  @override
  Future<List<EmployeeIsar>> findUnsynced(Isar isar) =>
      isar.employeeIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<EmployeeIsar?> findLocalById(Isar isar, String id) =>
      isar.employeeIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, EmployeeIsar record) =>
      isar.employeeIsars.put(record);

  @override
  String recordId(EmployeeIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(EmployeeIsar record) =>
      EmployeeRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      EmployeeRemoteMapper.applyRemote(isar, remote);
}

class OrderSyncHandler extends _CollectionHandler<OrderIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.order;

  @override
  String get tableName => SupabaseTableNames.orders;

  @override
  int get priority => 130;

  @override
  Future<List<OrderIsar>> findUnsynced(Isar isar) =>
      isar.orderIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<OrderIsar?> findLocalById(Isar isar, String id) =>
      isar.orderIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, OrderIsar record) => isar.orderIsars.put(record);

  @override
  String recordId(OrderIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(OrderIsar record) =>
      OrderRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      OrderRemoteMapper.applyRemote(isar, remote);
}

class OrderItemSyncHandler extends _CollectionHandler<OrderItemIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.orderItem;

  @override
  String get tableName => SupabaseTableNames.orderItems;

  @override
  int get priority => 140;

  @override
  Future<List<OrderItemIsar>> findUnsynced(Isar isar) =>
      isar.orderItemIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<OrderItemIsar?> findLocalById(Isar isar, String id) =>
      isar.orderItemIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, OrderItemIsar record) =>
      isar.orderItemIsars.put(record);

  @override
  String recordId(OrderItemIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(OrderItemIsar record) =>
      OrderItemRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      OrderItemRemoteMapper.applyRemote(isar, remote);
}

class AttendanceRecordSyncHandler extends _CollectionHandler<AttendanceRecordIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.attendanceRecord;

  @override
  String get tableName => SupabaseTableNames.attendanceRecords;

  @override
  int get priority => 150;

  @override
  Future<List<AttendanceRecordIsar>> findUnsynced(Isar isar) =>
      isar.attendanceRecordIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<AttendanceRecordIsar?> findLocalById(Isar isar, String id) =>
      isar.attendanceRecordIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, AttendanceRecordIsar record) =>
      isar.attendanceRecordIsars.put(record);

  @override
  String recordId(AttendanceRecordIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(AttendanceRecordIsar record) =>
      AttendanceRecordRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      AttendanceRecordRemoteMapper.applyRemote(isar, remote);
}

class SalarySlipSyncHandler extends _CollectionHandler<SalarySlipIsar> {
  @override
  SyncEntityType get entityType => SyncEntityType.salarySlip;

  @override
  String get tableName => SupabaseTableNames.salarySlips;

  @override
  int get priority => 160;

  @override
  Future<List<SalarySlipIsar>> findUnsynced(Isar isar) =>
      isar.salarySlipIsars.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<SalarySlipIsar?> findLocalById(Isar isar, String id) =>
      isar.salarySlipIsars.filter().uuidEqualTo(id).findFirst();

  @override
  Future<void> putLocal(Isar isar, SalarySlipIsar record) =>
      isar.salarySlipIsars.put(record);

  @override
  String recordId(SalarySlipIsar record) => record.uuid;

  @override
  Map<String, dynamic> toRemote(SalarySlipIsar record) =>
      SalarySlipRemoteMapper.toRemote(record);

  @override
  Future<void> writeRemoteToLocal(
    Isar isar,
    Map<String, dynamic> remote,
  ) =>
      SalarySlipRemoteMapper.applyRemote(isar, remote);
}
