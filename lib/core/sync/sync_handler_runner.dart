import 'dart:convert';

import 'package:isar/isar.dart';

import 'sync_conflict.dart';
import 'sync_entity_handler.dart';
import 'sync_queue_models.dart';
import 'sync_remote_codec.dart';

const syncDownloadPageSize = 200;

Future<EntitySyncResult> runCollectionSync<R>({
  required SyncEntityContext context,
  required SyncEntityType entityType,
  required String tableName,
  required Future<List<R>> Function(Isar isar) findUnsynced,
  required Map<String, dynamic> Function(R record) toRemote,
  required Future<R?> Function(Isar isar, String id) findLocalById,
  required Future<void> Function(Isar isar, R record) putLocal,
  required Future<void> Function(Isar isar, Map<String, dynamic> remote)
      writeRemoteToLocal,
  required String Function(R record) recordId,
  required int Function(R record) versionOf,
  required DateTime Function(R record) updatedAtOf,
  required bool Function(R record) isDeleteOf,
  required Map<String, dynamic> Function(R record) localSnapshot,
}) async {
  var uploaded = 0;
  var downloaded = 0;
  var conflicts = 0;
  DateTime? maxRemoteUpdatedAt;

  final pending = await findUnsynced(context.isar);
  for (final record in pending) {
    await context.client.from(tableName).upsert(toRemote(record));
    await context.isar.writeTxn(() async {
      final current = await findLocalById(context.isar, recordId(record));
      if (current == null) return;
      (current as dynamic).isSynced = true;
      await putLocal(context.isar, current);
    });
    uploaded += 1;
  }

  final since = context.downloadSince ?? DateTime.fromMillisecondsSinceEpoch(0);
  final rows = await context.client
      .from(tableName)
      .select()
      .gt('updated_at', since.toUtc().toIso8601String())
      .order('updated_at')
      .limit(syncDownloadPageSize);

  for (final raw in rows) {
    final remote = Map<String, dynamic>.from(raw as Map);
    final id = remote['id'] as String;
    final remoteUpdatedAt = SyncRemoteCodec.parseDateTime(remote['updated_at']);
    if (maxRemoteUpdatedAt == null ||
        remoteUpdatedAt.isAfter(maxRemoteUpdatedAt)) {
      maxRemoteUpdatedAt = remoteUpdatedAt;
    }

    final local = await findLocalById(context.isar, id);
    final outcome = await _applyRemoteWithConflict<R>(
      context: context,
      entityType: entityType,
      local: local,
      remote: remote,
      versionOf: versionOf,
      updatedAtOf: updatedAtOf,
      isDeleteOf: isDeleteOf,
      localSnapshot: localSnapshot,
      writeRemoteToLocal: (row) => writeRemoteToLocal(context.isar, row),
    );

    if (outcome.applied) downloaded += 1;
    if (outcome.conflict) conflicts += 1;
  }

  return EntitySyncResult(
    uploaded: uploaded,
    downloaded: downloaded,
    conflicts: conflicts,
    maxRemoteUpdatedAt: maxRemoteUpdatedAt,
  );
}

Future<ApplyRemoteOutcome> _applyRemoteWithConflict<R>({
  required SyncEntityContext context,
  required SyncEntityType entityType,
  required R? local,
  required Map<String, dynamic> remote,
  required int Function(R record) versionOf,
  required DateTime Function(R record) updatedAtOf,
  required bool Function(R record) isDeleteOf,
  required Map<String, dynamic> Function(R record) localSnapshot,
  required Future<void> Function(Map<String, dynamic> remote) writeRemoteToLocal,
}) async {
  final remoteVersion = SyncRemoteCodec.parseInt(remote['version']);
  final remoteUpdatedAt = SyncRemoteCodec.parseDateTime(remote['updated_at']);
  final remoteId = remote['id'] as String;

  if (local == null) {
    await writeRemoteToLocal(remote);
    return ApplyRemoteOutcome(
      applied: true,
      remoteUpdatedAt: remoteUpdatedAt,
    );
  }

  final localRecord = local;
  final localSynced = (localRecord as dynamic).isSynced as bool;
  if (localSynced) {
    if (remoteUpdatedAt.isAfter(updatedAtOf(localRecord))) {
      await writeRemoteToLocal(remote);
      return ApplyRemoteOutcome(
        applied: true,
        remoteUpdatedAt: remoteUpdatedAt,
      );
    }
    return ApplyRemoteOutcome(remoteUpdatedAt: remoteUpdatedAt);
  }

  final winner = SyncConflictResolver.resolve(
    localIsDelete: isDeleteOf(localRecord),
    localVersion: versionOf(localRecord),
    localUpdatedAt: updatedAtOf(localRecord),
    remoteVersion: remoteVersion,
    remoteUpdatedAt: remoteUpdatedAt,
  );

  if (winner == ConflictWinner.local) {
    context.conflictLogger.log(
      SyncConflictLogEntry(
        entityType: entityType,
        recordId: remoteId,
        winner: ConflictWinner.local,
        localVersion: versionOf(localRecord),
        remoteVersion: remoteVersion,
        localUpdatedAt: updatedAtOf(localRecord),
        remoteUpdatedAt: remoteUpdatedAt,
        losingPayloadJson: jsonEncode(remote),
        resolvedAt: DateTime.now(),
        reason: isDeleteOf(localRecord)
            ? 'Local delete wins over remote edit'
            : 'Higher local version/timestamp',
      ),
    );
    return ApplyRemoteOutcome(
      conflict: true,
      remoteUpdatedAt: remoteUpdatedAt,
    );
  }

  context.conflictLogger.log(
    SyncConflictLogEntry(
      entityType: entityType,
      recordId: remoteId,
      winner: ConflictWinner.remote,
      localVersion: versionOf(localRecord),
      remoteVersion: remoteVersion,
      localUpdatedAt: updatedAtOf(localRecord),
      remoteUpdatedAt: remoteUpdatedAt,
      losingPayloadJson: jsonEncode(localSnapshot(localRecord)),
      resolvedAt: DateTime.now(),
      reason: 'Remote version/timestamp won pending local changes',
    ),
  );
  await writeRemoteToLocal(remote);
  return ApplyRemoteOutcome(
    applied: true,
    conflict: true,
    remoteUpdatedAt: remoteUpdatedAt,
  );
}
