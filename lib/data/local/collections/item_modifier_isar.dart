import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'item_modifier_isar.g.dart';

@collection
class ItemModifierIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String groupId;

  late String name;

  double priceDelta = 0;

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
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static ItemModifierIsar create({
    required String groupId,
    required String name,
    required double priceDelta,
    required String deviceId,
    required int sortOrder,
  }) {
    final now = DateTime.now();
    return ItemModifierIsar()
      ..uuid = const Uuid().v4()
      ..groupId = groupId
      ..name = name
      ..priceDelta = priceDelta
      ..sortOrder = sortOrder
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  ItemModifierIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  ItemModifierIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
