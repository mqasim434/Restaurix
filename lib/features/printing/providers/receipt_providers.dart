import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/isar_service.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../receipt/receipt_data.dart';
import '../receipt/receipt_service.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(
    isar: ref.watch(isarProvider),
    orderRepository: ref.watch(orderRepositoryProvider),
    settingsRepository: ref.watch(appSettingRepositoryProvider),
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
  }) {
    return _ref.read(receiptServiceProvider).printOrder(
          orderId: orderId,
          isReprint: isReprint,
          forPlacement: forPlacement,
        );
  }
}
