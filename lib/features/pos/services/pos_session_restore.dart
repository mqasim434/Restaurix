import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/pos_draft_snapshot.dart';
import '../providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/discount_providers.dart';
import '../providers/order_edit_provider.dart';

/// Restores a serialized POS session into live cart/checkout providers.
void restorePosSession(Ref ref, PosDraftSnapshot snapshot) {
  ref.read(editingOrderIdProvider.notifier).state = null;
  ref.read(cartProvider.notifier).clear();
  ref.read(cartDiscountsProvider.notifier).replaceAll(snapshot.discounts);

  for (final item in snapshot.cartItems) {
    ref.read(cartProvider.notifier).add(item);
  }

  ref.read(checkoutProvider.notifier).restoreDraft(snapshot.checkoutWithoutPayment);
}

PosDraftSnapshot capturePosSession(Ref ref) {
  return PosDraftSnapshot(
    checkout: ref.read(checkoutProvider),
    cartItems: ref.read(cartProvider),
    discounts: ref.read(cartDiscountsProvider),
  );
}
