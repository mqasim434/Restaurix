import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'deal_item_isar.g.dart';

@collection
class DealItemIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String dealId;

  @Index()
  late String productId;

  String? variantId;

  int quantity = 1;

  bool allowModifiers = false;

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

  static DealItemIsar create({
    required String dealId,
    required String productId,
    required String deviceId,
    String? variantId,
    int quantity = 1,
    bool allowModifiers = false,
  }) {
    final now = DateTime.now();
    return DealItemIsar()
      ..uuid = const Uuid().v4()
      ..dealId = dealId
      ..productId = productId
      ..variantId = variantId
      ..quantity = quantity
      ..allowModifiers = allowModifiers
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  DealItemIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  DealItemIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
