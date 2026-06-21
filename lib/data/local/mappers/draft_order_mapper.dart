import 'dart:convert';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/draft_order.dart';
import '../../../domain/models/pos_draft_snapshot.dart';
import '../collections/draft_order_isar.dart';

DraftOrder draftOrderFromIsar(DraftOrderIsar record) {
  return DraftOrder(
    id: record.uuid,
    label: record.label,
    payloadJson: record.payloadJson,
    tableId: record.tableId,
    createdByUserId: record.createdByUserId,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

PosDraftSnapshot snapshotFromDraft(DraftOrder draft) {
  final decoded = jsonDecode(draft.payloadJson) as Map<String, dynamic>;
  return PosDraftSnapshot.fromJson(decoded);
}

String encodeSnapshot(PosDraftSnapshot snapshot) {
  return jsonEncode(snapshot.toJson());
}

DraftOrderIsar draftOrderToIsar({
  required DraftOrder draft,
  required String deviceId,
  required SyncAction action,
}) {
  return DraftOrderIsar()
    ..uuid = draft.id
    ..label = draft.label
    ..payloadJson = draft.payloadJson
    ..tableId = draft.tableId
    ..createdByUserId = draft.createdByUserId
    ..createdAt = draft.createdAt
    ..updatedAt = draft.updatedAt
    ..isSynced = draft.isSynced
    ..deletedAt = draft.deletedAt
    ..syncAction = action.name
    ..deviceId = deviceId
    ..version = draft.version;
}
