import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../core/constants.dart';

part 'product_isar.g.dart';

@collection
class ProductIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;

  @Index()
  late String categoryId;

  double basePrice = 0;

  String? description;

  String? imageUrl;

  @Index()
  bool isAvailable = true;

  late String kitchenCategory;

  String? printerId;

  int estimatedPrepMinutes = AppConstants.defaultProductPrepMinutes;

  /// Assigned modifier group UUIDs — see [modifierGroupAssignmentDoc].
  List<String> modifierGroupIds = [];

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

  static ProductIsar create({
    required String name,
    required String categoryId,
    required double basePrice,
    required String deviceId,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
    String kitchenCategory = '',
    String? printerId,
    int estimatedPrepMinutes = AppConstants.defaultProductPrepMinutes,
  }) {
    final now = DateTime.now();
    return ProductIsar()
      ..uuid = const Uuid().v4()
      ..name = name
      ..categoryId = categoryId
      ..basePrice = basePrice
      ..description = description
      ..imageUrl = imageUrl
      ..isAvailable = isAvailable
      ..kitchenCategory = kitchenCategory
      ..printerId = printerId
      ..estimatedPrepMinutes = estimatedPrepMinutes
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  ProductIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  ProductIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
