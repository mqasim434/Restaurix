import '../../core/sync/sync_action.dart';

/// Syncable entity types tracked by the offline sync queue.
enum SyncEntityType {
  category,
  product,
  productVariant,
  deal,
  dealItem,
  hall,
  restaurantTable,
  order,
  orderItem,
  draftOrder,
  rider,
  pickupCompany,
  employee,
  creditCustomer,
  creditTransaction,
  attendanceRecord,
  salarySlip,
}

extension SyncEntityTypeLabels on SyncEntityType {
  String get label => switch (this) {
        SyncEntityType.category => 'Categories',
        SyncEntityType.product => 'Products',
        SyncEntityType.productVariant => 'Product variants',
        SyncEntityType.deal => 'Deals',
        SyncEntityType.dealItem => 'Deal items',
        SyncEntityType.hall => 'Halls',
        SyncEntityType.restaurantTable => 'Tables',
        SyncEntityType.order => 'Orders',
        SyncEntityType.orderItem => 'Order items',
        SyncEntityType.draftOrder => 'Draft orders',
        SyncEntityType.rider => 'Riders',
        SyncEntityType.pickupCompany => 'Pickup companies',
        SyncEntityType.employee => 'Employees',
        SyncEntityType.creditCustomer => 'Credit customers',
        SyncEntityType.creditTransaction => 'Credit transactions',
        SyncEntityType.attendanceRecord => 'Attendance',
        SyncEntityType.salarySlip => 'Salary slips',
      };
}

/// One unsynced record — latest local state only, not a change log.
class SyncQueueEntry {
  const SyncQueueEntry({
    required this.entityType,
    required this.recordId,
    required this.syncAction,
    required this.updatedAt,
    required this.isSoftDeleted,
    required this.version,
  });

  final SyncEntityType entityType;
  final String recordId;
  final SyncAction syncAction;
  final DateTime updatedAt;
  final bool isSoftDeleted;
  final int version;
}

/// Pending sync state grouped by entity type.
class SyncQueueSnapshot {
  const SyncQueueSnapshot({
    required this.entries,
    required this.countsByType,
    required this.totalCount,
  });

  final List<SyncQueueEntry> entries;
  final Map<SyncEntityType, int> countsByType;
  final int totalCount;

  static const empty = SyncQueueSnapshot(
    entries: [],
    countsByType: {},
    totalCount: 0,
  );
}
