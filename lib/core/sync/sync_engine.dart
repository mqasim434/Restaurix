import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../config/env_config.dart';
import '../../data/remote/supabase_service.dart';
import 'sync_conflict.dart';
import 'sync_cursor_store.dart';
import 'sync_entity_handler.dart';
import 'sync_handlers.dart';
import 'sync_queue_models.dart';

enum SyncRunState {
  idle,
  syncing,
  error,
  offline,
  disabled,
}

class SyncCycleResult {
  const SyncCycleResult({
    required this.success,
    required this.uploaded,
    required this.downloaded,
    required this.conflicts,
    this.errorMessage,
    this.completedAt,
  });

  final bool success;
  final int uploaded;
  final int downloaded;
  final int conflicts;
  final String? errorMessage;
  final DateTime? completedAt;
}

/// Bidirectional Supabase sync. Each entity type syncs independently so
/// interruption mid-cycle is resumable without corrupting other collections.
///
/// Conflict policy: local soft-deletes win over remote edits; otherwise higher
/// [version] wins, then [updatedAt] as tiebreaker. Losing payloads are logged.
class SyncEngine {
  SyncEngine({
    required Isar isar,
    required SyncCursorStore cursorStore,
    required SupabaseService supabaseService,
    List<SyncEntityHandler>? handlers,
  })  : _isar = isar,
        _cursorStore = cursorStore,
        _supabaseService = supabaseService,
        _handlers = handlers ?? buildSyncEntityHandlers();

  final Isar _isar;
  final SyncCursorStore _cursorStore;
  final SupabaseService _supabaseService;
  final List<SyncEntityHandler> _handlers;

  var _isRunning = false;

  bool get isRunning => _isRunning;

  Future<SyncCycleResult> runCycle({
    SyncConflictLogger? conflictLogger,
  }) async {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      return const SyncCycleResult(
        success: false,
        uploaded: 0,
        downloaded: 0,
        conflicts: 0,
        errorMessage: 'Supabase is not configured',
      );
    }

    if (_isRunning) {
      return const SyncCycleResult(
        success: false,
        uploaded: 0,
        downloaded: 0,
        conflicts: 0,
        errorMessage: 'Sync already in progress',
      );
    }

    _isRunning = true;
    final logger = conflictLogger ?? SyncConflictLogger([]);
    var uploaded = 0;
    var downloaded = 0;
    var conflicts = 0;
    String? errorMessage;

    try {
      final client = _supabaseService.client;

      for (final handler in _handlers) {
        try {
          final since = await _cursorStore.getEntityCursor(handler.entityType);
          final result = await handler.sync(
            SyncEntityContext(
              isar: _isar,
              client: client,
              downloadSince: since,
              conflictLogger: logger,
            ),
          );
          uploaded += result.uploaded;
          downloaded += result.downloaded;
          conflicts += result.conflicts;

          if (result.maxRemoteUpdatedAt != null) {
            await _cursorStore.setEntityCursor(
              handler.entityType,
              result.maxRemoteUpdatedAt!,
            );
          }
        } catch (error, stackTrace) {
          debugPrint(
            'SyncEngine: ${handler.entityType.name} failed: $error\n$stackTrace',
          );
          errorMessage = '${handler.entityType.label}: $error';
        }
      }

      if (errorMessage == null) {
        await _cursorStore.setLastSuccessfulSyncAt(DateTime.now());
      }
      await _cursorStore.saveConflictLog(
        SyncConflictLogger.encodeStored(logger.entries),
      );

      return SyncCycleResult(
        success: errorMessage == null,
        uploaded: uploaded,
        downloaded: downloaded,
        conflicts: conflicts,
        errorMessage: errorMessage,
        completedAt: DateTime.now(),
      );
    } catch (error) {
      return SyncCycleResult(
        success: false,
        uploaded: uploaded,
        downloaded: downloaded,
        conflicts: conflicts,
        errorMessage: error.toString(),
        completedAt: DateTime.now(),
      );
    } finally {
      _isRunning = false;
    }
  }
}
