import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/table_status.dart';

part 'restaurant_table_isar.g.dart';

@collection
class RestaurantTableIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String hallId;

  late String label;

  int capacity = 4;

  late String status;

  String? currentOrderId;

  @Index()
  int sortOrder = 0;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  TableStatus get statusEnum => TableStatus.values.byName(status);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static RestaurantTableIsar create({
    required String hallId,
    required String label,
    required String deviceId,
    required int sortOrder,
    int capacity = 4,
    TableStatus status = TableStatus.available,
  }) {
    final now = DateTime.now();
    return RestaurantTableIsar()
      ..uuid = const Uuid().v4()
      ..hallId = hallId
      ..label = label
      ..capacity = capacity
      ..status = status.name
      ..currentOrderId = null
      ..sortOrder = sortOrder
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  RestaurantTableIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  RestaurantTableIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
