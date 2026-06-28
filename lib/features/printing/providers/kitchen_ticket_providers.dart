import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/isar_service.dart';
import '../../../data/repositories/app_setting_repository.dart';
import '../../orders/providers/order_management_providers.dart';
import '../kitchen_ticket/kitchen_ticket_data.dart';
import '../kitchen_ticket/kitchen_ticket_service.dart';

final appSettingRepositoryProvider = Provider<AppSettingRepository>((ref) {
  return AppSettingRepository(ref.watch(isarProvider));
});

final kitchenTicketServiceProvider = Provider<KitchenTicketService>((ref) {
  return KitchenTicketService(
    isar: ref.watch(isarProvider),
    orderRepository: ref.watch(orderRepositoryProvider),
    settingsRepository: ref.watch(appSettingRepositoryProvider),
  );
});

final kitchenTicketPrintControllerProvider =
    Provider<KitchenTicketPrintController>((ref) {
  return KitchenTicketPrintController(ref);
});

class KitchenTicketPrintController {
  KitchenTicketPrintController(this._ref);

  final Ref _ref;

  Future<KitchenTicketPrintResult> printOrder({
    required String orderId,
    required bool isReprint,
  }) {
    return _ref.read(kitchenTicketServiceProvider).printOrder(
          orderId: orderId,
          isReprint: isReprint,
        );
  }
}
