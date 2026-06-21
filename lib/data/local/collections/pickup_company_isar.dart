import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'pickup_company_isar.g.dart';

@collection
class PickupCompanyIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  String? logoUrl;

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

  static PickupCompanyIsar create({
    required String name,
    required String deviceId,
    String? logoUrl,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return PickupCompanyIsar()
      ..uuid = const Uuid().v4()
      ..name = name
      ..logoUrl = logoUrl
      ..isActive = isActive
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }
}
