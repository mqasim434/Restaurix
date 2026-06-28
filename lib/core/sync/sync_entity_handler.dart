import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_conflict.dart';
import 'sync_queue_models.dart';

class EntitySyncResult {
  const EntitySyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.conflicts = 0,
    this.maxRemoteUpdatedAt,
  });

  final int uploaded;
  final int downloaded;
  final int conflicts;
  final DateTime? maxRemoteUpdatedAt;

  EntitySyncResult merge(EntitySyncResult other) {
    DateTime? maxAt = maxRemoteUpdatedAt;
    final otherMax = other.maxRemoteUpdatedAt;
    if (otherMax != null && (maxAt == null || otherMax.isAfter(maxAt))) {
      maxAt = otherMax;
    }
    return EntitySyncResult(
      uploaded: uploaded + other.uploaded,
      downloaded: downloaded + other.downloaded,
      conflicts: conflicts + other.conflicts,
      maxRemoteUpdatedAt: maxAt,
    );
  }
}

class SyncEntityContext {
  const SyncEntityContext({
    required this.isar,
    required this.client,
    required this.downloadSince,
    required this.conflictLogger,
  });

  final Isar isar;
  final SupabaseClient client;
  final DateTime? downloadSince;
  final SyncConflictLogger conflictLogger;
}

abstract class SyncEntityHandler {
  SyncEntityType get entityType;
  String get tableName;
  int get priority;

  Future<EntitySyncResult> sync(SyncEntityContext context);
}

class ApplyRemoteOutcome {
  const ApplyRemoteOutcome({
    this.applied = false,
    this.conflict = false,
    this.remoteUpdatedAt,
  });

  final bool applied;
  final bool conflict;
  final DateTime? remoteUpdatedAt;
}
