import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_setting_keys.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/tablet_order_providers.dart';

final tabletOrderAutoPrintServiceProvider =
    Provider<TabletOrderAutoPrintService>((ref) {
  return TabletOrderAutoPrintService(ref);
});

/// Tracks incoming tablet orders for the Live Orders board.
///
/// Kitchen + customer receipts print together after charge confirmation
/// (Enter on service/delivery charges) — not automatically on arrival.
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

    for (final orderId in pending) {
      if (_printedOrderIds.contains(orderId)) {
        tracker.markPrinted(orderId);
        continue;
      }

      final order = await _ref.read(orderRepositoryProvider).findById(orderId);
      if (order == null) continue;

      // Keep pending until Live Orders confirms charges and prints both slips.
      tracker.markPending(orderId);
    }
  }

  /// Called after kitchen + customer slips print on charge confirmation.
  Future<void> markSlipsPrinted(String orderId) async {
    await _ensurePrintedLoaded();
    _printedOrderIds.add(orderId);
    _ref.read(tabletOrderPrintTrackerProvider.notifier).markPrinted(orderId);
    await _persistPrintedIds();
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
