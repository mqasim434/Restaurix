import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/modifier_selection_type.dart';

part 'modifier_group_isar.g.dart';

@collection
class ModifierGroupIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  late String selectionType;

  bool isRequired = false;

  int minSelections = 0;

  int? maxSelections;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  ModifierSelectionType get selectionTypeEnum =>
      ModifierSelectionType.values.byName(selectionType);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static ModifierGroupIsar create({
    required String name,
    required String deviceId,
    ModifierSelectionType selectionType = ModifierSelectionType.multiple,
    bool isRequired = false,
    int minSelections = 0,
    int? maxSelections,
  }) {
    final now = DateTime.now();
    return ModifierGroupIsar()
      ..uuid = const Uuid().v4()
      ..name = name
      ..selectionType = selectionType.name
      ..isRequired = isRequired
      ..minSelections = minSelections
      ..maxSelections = maxSelections
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  ModifierGroupIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  ModifierGroupIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
