import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'draft_order_isar.g.dart';

@collection
class DraftOrderIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  String? label;

  late String payloadJson;

  @Index()
  String? tableId;

  late String createdByUserId;

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

  DraftOrderIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  DraftOrderIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  static DraftOrderIsar create({
    required String payloadJson,
    required String createdByUserId,
    required String deviceId,
    String? label,
    String? tableId,
  }) {
    final now = DateTime.now();
    return DraftOrderIsar()
      ..uuid = const Uuid().v4()
      ..label = label?.trim().isEmpty == true ? null : label?.trim()
      ..payloadJson = payloadJson
      ..tableId = tableId
      ..createdByUserId = createdByUserId
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }
}
