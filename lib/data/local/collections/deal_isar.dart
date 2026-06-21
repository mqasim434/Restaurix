import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'deal_isar.g.dart';

@collection
class DealIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  String? description;

  String? imageUrl;

  @Index()
  String? categoryId;

  double price = 0;

  @Index()
  bool isAvailable = true;

  DateTime? availabilityStart;

  DateTime? availabilityEnd;

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

  static DealIsar create({
    required String name,
    required double price,
    required String deviceId,
    String? description,
    String? imageUrl,
    String? categoryId,
    bool isAvailable = true,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
  }) {
    final now = DateTime.now();
    return DealIsar()
      ..uuid = const Uuid().v4()
      ..name = name
      ..description = description
      ..imageUrl = imageUrl
      ..categoryId = categoryId
      ..price = price
      ..isAvailable = isAvailable
      ..availabilityStart = availabilityStart
      ..availabilityEnd = availabilityEnd
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  DealIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  DealIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
