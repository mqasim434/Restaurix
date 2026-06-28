import '../models/cart_item.dart';
import 'kitchen_constants.dart';

/// Resolves effective prep minutes for a cart line at order placement.
abstract final class KitchenPrepResolver {
  static int resolveItemPrepMinutes({
    required CartItem item,
    required int? orderPromisedPrepMinutes,
    required Map<String, int> productPrepMinutesById,
  }) {
    if (orderPromisedPrepMinutes != null) {
      return orderPromisedPrepMinutes.clamp(1, 999);
    }

    final productId = item.productId;
    if (productId != null) {
      return (productPrepMinutesById[productId] ??
              KitchenConstants.defaultPrepMinutes)
          .clamp(1, 999);
    }

    return KitchenConstants.defaultPrepMinutes;
  }
}
