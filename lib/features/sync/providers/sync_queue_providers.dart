import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_queue_models.dart';
import '../../../data/local/isar_service.dart';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService(ref.watch(isarProvider));
});

final syncQueueSnapshotProvider = StreamProvider<SyncQueueSnapshot>((ref) {
  return ref.watch(syncQueueServiceProvider).watchQueue();
});

final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(syncQueueSnapshotProvider).maybeWhen(
        data: (snapshot) => snapshot.totalCount,
        orElse: () => 0,
      );
});
