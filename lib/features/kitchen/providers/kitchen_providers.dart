import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/kitchen_repository.dart';
import '../../../domain/models/kitchen_board.dart';

final kitchenRepositoryProvider = Provider<KitchenRepository>((ref) {
  return KitchenRepository(ref.watch(isarProvider));
});

final kitchenBoardProvider = StreamProvider<KitchenBoard>((ref) {
  return ref.watch(kitchenRepositoryProvider).watchBoard();
});

/// Starts a 1-second tick that auto-advances due kitchen items while active.
final kitchenAutoAdvanceProvider = Provider<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    unawaited(
      ref.read(kitchenRepositoryProvider).processDueItems(
            deviceId: ref.read(deviceIdProvider),
          ),
    );
  });
  ref.onDispose(timer.cancel);
});

final kitchenControllerProvider = Provider<KitchenController>((ref) {
  return KitchenController(ref);
});

class KitchenController {
  KitchenController(this._ref);

  final Ref _ref;

  Future<void> processDueItems() {
    return _ref.read(kitchenRepositoryProvider).processDueItems(
          deviceId: _ref.read(deviceIdProvider),
        );
  }
}
