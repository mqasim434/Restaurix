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

final kitchenControllerProvider = Provider<KitchenController>((ref) {
  return KitchenController(ref);
});

class KitchenController {
  KitchenController(this._ref);

  final Ref _ref;

  Future<void> advanceItem(String orderItemId) {
    return _ref.read(kitchenRepositoryProvider).advanceItem(
          orderItemId: orderItemId,
          deviceId: _ref.read(deviceIdProvider),
        );
  }
}
