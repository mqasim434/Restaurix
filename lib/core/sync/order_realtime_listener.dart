import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/supabase_table_names.dart';

typedef OrderRealtimeSyncCallback = Future<void> Function();
typedef TabletOrderInsertedCallback = void Function({
  required String orderId,
  required String orderNumber,
  required Map<String, dynamic> record,
});

/// Listens for new rows on the Supabase `orders` table and triggers a sync pull
/// so the desktop order list updates without waiting for the periodic interval.
class OrderRealtimeListener {
  OrderRealtimeListener({
    required SupabaseClient client,
    required OrderRealtimeSyncCallback onSyncRequested,
    required bool Function(Map<String, dynamic> record) isTabletOrderRecord,
    required TabletOrderInsertedCallback onTabletOrderInserted,
    Duration syncDebounce = const Duration(milliseconds: 400),
  })  : _client = client,
        _onSyncRequested = onSyncRequested,
        _isTabletOrderRecord = isTabletOrderRecord,
        _onTabletOrderInserted = onTabletOrderInserted,
        _syncDebounce = syncDebounce;

  final SupabaseClient _client;
  final OrderRealtimeSyncCallback _onSyncRequested;
  final bool Function(Map<String, dynamic> record) _isTabletOrderRecord;
  final TabletOrderInsertedCallback _onTabletOrderInserted;
  final Duration _syncDebounce;

  RealtimeChannel? _channel;
  Timer? _syncTimer;
  var _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _channel = _client
        .channel('restaurix-order-inserts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseTableNames.orders,
          callback: _handleInsert,
        )
        .subscribe((status, [error]) {
      if (error != null) {
        debugPrint('OrderRealtimeListener: subscribe error — $error');
        return;
      }
      debugPrint('OrderRealtimeListener: channel status — $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('OrderRealtimeListener: listening for order inserts');
      }
    });
  }

  void _handleInsert(PostgresChangePayload payload) {
    final record = Map<String, dynamic>.from(payload.newRecord);
    final orderId = record['id']?.toString();
    final orderNumber = record['order_number']?.toString();

    debugPrint(
      'OrderRealtimeListener: insert '
      '${orderNumber ?? orderId ?? 'unknown'}',
    );

    _scheduleSyncPull();

    if (orderId == null || orderNumber == null) return;
    if (!_isTabletOrderRecord(record)) return;

    _onTabletOrderInserted(
      orderId: orderId,
      orderNumber: orderNumber,
      record: record,
    );
  }

  void _scheduleSyncPull() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDebounce, () {
      _onSyncRequested().ignore();
    });
  }

  Future<void> dispose() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    final channel = _channel;
    _channel = null;
    _started = false;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
