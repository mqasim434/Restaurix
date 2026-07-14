import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_setting_keys.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../../data/local/device_id_service.dart';
import '../../printing/providers/kitchen_ticket_providers.dart';
import '../../printing/providers/receipt_providers.dart';
import '../providers/tablet_order_providers.dart';

final tabletOrderAutoPrintServiceProvider =
    Provider<TabletOrderAutoPrintService>((ref) {
  return TabletOrderAutoPrintService(ref);
});

/// Prints kitchen + customer slips for tablet orders after sync pulls them locally.
class TabletOrderAutoPrintService {
  TabletOrderAutoPrintService(this._ref);

  final Ref _ref;
  var _printedLoaded = false;
  final _printedOrderIds = <String>{};

  Future<void> onMobileOrderDetected(String orderId) async {
    await _ensurePrintedLoaded();
    if (_printedOrderIds.contains(orderId)) return;

    _ref.read(tabletOrderPrintTrackerProvider.notifier).markPending(orderId);
  }

  Future<void> processAfterSync() async {
    await _ensurePrintedLoaded();

    final tracker = _ref.read(tabletOrderPrintTrackerProvider.notifier);
    final pending = _ref.read(tabletOrderPrintTrackerProvider).pendingOrderIds;
    final recentTabletOrders = await _ref
        .read(orderRepositoryProvider)
        .findRecentTabletOrders(_ref.read(deviceIdProvider));

    final targetIds = <String>{
      ...pending,
      for (final order in recentTabletOrders)
        if (!_printedOrderIds.contains(order.id)) order.id,
    };

    for (final orderId in targetIds) {
      if (_printedOrderIds.contains(orderId)) continue;

      final order = await _ref.read(orderRepositoryProvider).findById(orderId);
      if (order == null) {
        tracker.markPending(orderId);
        continue;
      }

      final success = await _printSlips(orderId);
      if (success) {
        _printedOrderIds.add(orderId);
        tracker.markPrinted(orderId);
        await _persistPrintedIds();
      } else {
        tracker.markFailed(orderId);
      }
    }
  }

  Future<bool> _printSlips(String orderId) async {
    try {
      final kitchenResult = await _ref
          .read(kitchenTicketPrintControllerProvider)
          .printOrder(orderId: orderId, isReprint: false);
      final receiptResult = await _ref
          .read(receiptPrintControllerProvider)
          .printOrder(
            orderId: orderId,
            isReprint: false,
            forPlacement: true,
          );

      if (kitchenResult.hasWarnings) {
        debugPrint(
          'Tablet auto-print kitchen warnings ($orderId): '
          '${kitchenResult.warnings.join('; ')}',
        );
      }
      if (receiptResult.hasWarnings) {
        debugPrint(
          'Tablet auto-print receipt warnings ($orderId): '
          '${receiptResult.warnings.join('; ')}',
        );
      }

      return kitchenResult.anyPrinted && receiptResult.printed;
    } catch (error, stackTrace) {
      debugPrint('Tablet auto-print failed for $orderId: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> _ensurePrintedLoaded() async {
    if (_printedLoaded) return;

    final repo = _ref.read(appSettingRepositoryProvider);
    final raw = await repo.getString(AppSettingKeys.tabletOrdersPrintedSlipIds);
    _printedOrderIds.addAll(_decodePrintedIds(raw));
    _ref
        .read(tabletOrderPrintTrackerProvider.notifier)
        .hydratePrintedIds(_printedOrderIds);
    _printedLoaded = true;
  }

  Future<void> _persistPrintedIds() async {
    final repo = _ref.read(appSettingRepositoryProvider);
    final encoded = jsonEncode(_printedOrderIds.toList()..sort());
    await repo.setString(AppSettingKeys.tabletOrdersPrintedSlipIds, encoded);
  }

  static Set<String> _decodePrintedIds(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }
}
