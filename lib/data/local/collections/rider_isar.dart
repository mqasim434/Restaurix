import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'rider_isar.g.dart';

@collection
class RiderIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  String? phone;

  @Index()
  bool isActive = true;

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

  static RiderIsar create({
    required String name,
    required String deviceId,
    String? phone,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return RiderIsar()
      ..uuid = const Uuid().v4()
      ..name = name
      ..phone = phone
      ..isActive = isActive
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }
}
