import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/isar_service.dart';
import '../../../domain/models/order.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../tablet_orders/providers/delivery_location_providers.dart';
import '../receipt/receipt_data.dart';
import '../receipt/receipt_service.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(
    isar: ref.watch(isarProvider),
    orderRepository: ref.watch(orderRepositoryProvider),
    settingsRepository: ref.watch(appSettingRepositoryProvider),
    deliveryLocationResolver: ref.watch(deliveryLocationResolverProvider),
  );
});

final receiptPrintControllerProvider = Provider<ReceiptPrintController>((ref) {
  return ReceiptPrintController(ref);
});

class ReceiptPrintController {
  ReceiptPrintController(this._ref);

  final Ref _ref;

  Future<ReceiptPrintResult> printOrder({
    required String orderId,
    required bool isReprint,
    bool forPlacement = false,
    Order? orderSnapshot,
  }) {
    return _ref.read(receiptServiceProvider).printOrder(
          orderId: orderId,
          isReprint: isReprint,
          forPlacement: forPlacement,
          orderSnapshot: orderSnapshot,
        );
  }
}
