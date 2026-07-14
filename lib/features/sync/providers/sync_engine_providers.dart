import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/sync/sync_conflict.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_cursor_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/remote/supabase_service.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/sync_queue_providers.dart';

class SyncUiState {
  const SyncUiState({
    this.runState = SyncRunState.disabled,
    this.lastSuccessfulSyncAt,
    this.lastError,
    this.lastUploaded = 0,
    this.lastDownloaded = 0,
    this.lastConflicts = 0,
    this.conflictLog = const [],
    this.isOnline = false,
  });

  final SyncRunState runState;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastError;
  final int lastUploaded;
  final int lastDownloaded;
  final int lastConflicts;
  final List<SyncConflictLogEntry> conflictLog;
  final bool isOnline;

  SyncUiState copyWith({
    SyncRunState? runState,
    DateTime? lastSuccessfulSyncAt,
    String? lastError,
    bool clearError = false,
    int? lastUploaded,
    int? lastDownloaded,
    int? lastConflicts,
    List<SyncConflictLogEntry>? conflictLog,
    bool? isOnline,
  }) {
    return SyncUiState(
      runState: runState ?? this.runState,
      lastSuccessfulSyncAt:
          lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastUploaded: lastUploaded ?? this.lastUploaded,
      lastDownloaded: lastDownloaded ?? this.lastDownloaded,
      lastConflicts: lastConflicts ?? this.lastConflicts,
      conflictLog: conflictLog ?? this.conflictLog,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

final syncConnectivityServiceProvider = Provider<SyncConnectivityService>((ref) {
  return SyncConnectivityService();
});

final syncCursorStoreProvider = Provider<SyncCursorStore>((ref) {
  return SyncCursorStore(ref.watch(appSettingRepositoryProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    isar: ref.watch(isarProvider),
    cursorStore: ref.watch(syncCursorStoreProvider),
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

final syncUiStateProvider =
    StateNotifierProvider<SyncUiController, SyncUiState>((ref) {
  return SyncUiController(ref);
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(
    connectivity: ref.watch(syncConnectivityServiceProvider),
    triggerSync: () => ref.read(syncUiStateProvider.notifier).syncNow(),
  );
});

class SyncUiController extends StateNotifier<SyncUiState> {
  SyncUiController(this._ref) : super(const SyncUiState()) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      state = state.copyWith(runState: SyncRunState.disabled);
      return;
    }

    final cursorStore = _ref.read(syncCursorStoreProvider);
    final lastSync = await cursorStore.getLastSuccessfulSyncAt();
    final conflictRaw = await cursorStore.getStoredConflictLog();
    final online = await _ref.read(syncConnectivityServiceProvider).isOnline();

    state = state.copyWith(
      runState: SyncRunState.idle,
      lastSuccessfulSyncAt: lastSync,
      conflictLog: SyncConflictLogger.decodeStored(conflictRaw),
      isOnline: online,
    );
  }

  Future<void> refreshConnectivity() async {
    final online = await _ref.read(syncConnectivityServiceProvider).isOnline();
    state = state.copyWith(
      isOnline: online,
      runState: online && state.runState == SyncRunState.offline
          ? SyncRunState.idle
          : state.runState,
    );
  }

  Future<void> syncNow() async {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      state = state.copyWith(
        runState: SyncRunState.disabled,
        lastError: EnvConfig.isSupabaseConfigured
            ? 'Supabase failed to initialize — restart the app'
            : EnvConfig.deploymentHint(),
      );
      return;
    }

    final online = await _ref.read(syncConnectivityServiceProvider).isOnline();
    if (!online) {
      state = state.copyWith(
        runState: SyncRunState.offline,
        isOnline: false,
        lastError: 'No network connection',
      );
      return;
    }

    final engine = _ref.read(syncEngineProvider);
    if (engine.isRunning) return;

    state = state.copyWith(
      runState: SyncRunState.syncing,
      clearError: true,
      isOnline: true,
    );

    final result = await engine.runCycle();
    final cursorStore = _ref.read(syncCursorStoreProvider);
    final lastSync = await cursorStore.getLastSuccessfulSyncAt();
    final conflictRaw = await cursorStore.getStoredConflictLog();

    state = state.copyWith(
      runState: result.success ? SyncRunState.idle : SyncRunState.error,
      lastSuccessfulSyncAt: lastSync,
      lastError: result.errorMessage,
      lastUploaded: result.uploaded,
      lastDownloaded: result.downloaded,
      lastConflicts: result.conflicts,
      conflictLog: SyncConflictLogger.decodeStored(conflictRaw),
      isOnline: true,
    );

    _ref.invalidate(syncQueueSnapshotProvider);
  }
}
