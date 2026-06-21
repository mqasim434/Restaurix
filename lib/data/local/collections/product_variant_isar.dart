import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'product_variant_isar.g.dart';

@collection
class ProductVariantIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String productId;

  late String name;

  double price = 0;

  @Index()
  int sortOrder = 0;

  bool isDefault = false;

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

  static ProductVariantIsar create({
    required String productId,
    required String name,
    required double price,
    required String deviceId,
    required int sortOrder,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return ProductVariantIsar()
      ..uuid = const Uuid().v4()
      ..productId = productId
      ..name = name
      ..price = price
      ..sortOrder = sortOrder
      ..isDefault = isDefault
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  ProductVariantIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  ProductVariantIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
