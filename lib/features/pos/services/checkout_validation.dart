import '../../../domain/models/order_enums.dart';
import '../../../domain/models/pos_checkout_draft.dart';

/// Validates checkout metadata before order placement (Module 15).
abstract final class CheckoutValidation {
  static String? validate(PosCheckoutDraft draft) {
    if (draft.orderType == null) {
      return 'Select an order type before checkout';
    }

    switch (draft.orderType!) {
      case OrderType.dineIn:
        if (draft.tableId == null) {
          return 'Select a table for dine-in orders';
        }
      case OrderType.takeaway:
        break;
      case OrderType.delivery:
        if (draft.deliveryMode == null) {
          return 'Select how this delivery is fulfilled';
        }
        switch (draft.deliveryMode!) {
          case DeliveryMode.ownRider:
            if (draft.riderId == null || draft.riderName == null) {
              return 'Select a rider for delivery orders';
            }
          case DeliveryMode.pickupCompany:
            if (draft.pickupCompanyId == null ||
                draft.pickupCompanyName == null) {
              return 'Select a pickup company for delivery orders';
            }
        }
    }

    return null;
  }
}
