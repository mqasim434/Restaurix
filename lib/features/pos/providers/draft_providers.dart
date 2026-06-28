import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/draft_order_repository.dart';
import '../../../domain/models/draft_order.dart';
import '../providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/discount_providers.dart';
import '../providers/order_edit_provider.dart';
import '../services/pos_session_restore.dart';

final draftOrderRepositoryProvider = Provider<DraftOrderRepository>((ref) {
  return DraftOrderRepository(ref.watch(isarProvider));
});

final draftOrderListProvider = StreamProvider<List<DraftOrder>>((ref) {
  return ref.watch(draftOrderRepositoryProvider).watchAll();
});

final draftOrderCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(draftOrderListProvider).whenData((drafts) => drafts.length);
});

final draftOrderControllerProvider = Provider<DraftOrderController>((ref) {
  return DraftOrderController(ref);
});

class DraftOrderController {
  DraftOrderController(this._ref);

  final Ref _ref;

  Future<void> save({String? label}) async {
    final snapshot = capturePosSession(_ref);
    await _ref.read(draftOrderRepositoryProvider).save(
          snapshot: snapshot,
          label: label,
          createdByUserId: _ref.read(currentUserProvider).id,
          deviceId: _ref.read(deviceIdProvider),
        );

    _ref.read(cartProvider.notifier).clear();
    _ref.read(cartDiscountsProvider.notifier).clear();
    _ref.read(editingOrderIdProvider.notifier).state = null;
    _ref.read(checkoutProvider.notifier).resetAfterDraftSave();
  }

  Future<void> resume(String draftId) async {
    final snapshot = await _ref.read(draftOrderRepositoryProvider).resume(
          draftId: draftId,
          deviceId: _ref.read(deviceIdProvider),
        );
    restorePosSession(_ref, snapshot);
  }

  Future<void> discard(String draftId) async {
    await _ref.read(draftOrderRepositoryProvider).discard(
          draftId: draftId,
          deviceId: _ref.read(deviceIdProvider),
        );
  }
}
