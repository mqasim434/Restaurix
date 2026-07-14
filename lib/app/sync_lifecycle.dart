import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/desktop_features.dart';
import '../core/config/env_config.dart';
import '../core/sync/order_realtime_listener.dart';
import '../core/sync/realtime_auth_binder.dart';
import '../core/sync/sync_coordinator.dart';
import '../core/sync/sync_engine.dart';
import '../data/local/device_id_service.dart';
import '../data/remote/supabase_service.dart';
import '../domain/services/tablet_order_detection.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/sync/providers/sync_engine_providers.dart';
import '../features/tablet_orders/providers/tablet_order_providers.dart';
import '../features/credit_customers/services/credit_order_charge_processor.dart';
import '../features/tablet_orders/services/tablet_order_auto_print_service.dart';
import 'router.dart';

/// Starts background sync scheduling and Supabase Realtime order listening.
class SyncLifecycle extends ConsumerStatefulWidget {
  const SyncLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncLifecycle> createState() => _SyncLifecycleState();
}

class _SyncLifecycleState extends ConsumerState<SyncLifecycle>
    with WidgetsBindingObserver {
  SyncCoordinator? _coordinator;
  OrderRealtimeListener? _orderRealtimeListener;
  var _realtimeAuthGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coordinator = ref.read(syncCoordinatorProvider);
      _coordinator!.start();
      _syncRealtimeWithAuth(ref.read(authControllerProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator?.dispose();
    _stopRealtimeListener();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncUiStateProvider.notifier).refreshConnectivity();
      ref.read(syncUiStateProvider.notifier).syncNow();
    }
  }

  Future<void> _syncRealtimeWithAuth(AuthState auth) async {
    final enabled = EnvConfig.isSupabaseConfigured &&
        SupabaseService.isInitialized &&
        auth.status == AuthStatus.authenticated;

    if (!enabled) {
      await _stopRealtimeListener();
      return;
    }

    final generation = ++_realtimeAuthGeneration;
    await RealtimeAuthBinder.applySession();
    if (!mounted || generation != _realtimeAuthGeneration) return;

    await _stopRealtimeListener();
    if (!mounted || generation != _realtimeAuthGeneration) return;

    final localDeviceId = ref.read(deviceIdProvider);
    _orderRealtimeListener = OrderRealtimeListener(
      client: ref.read(supabaseClientProvider),
      onSyncRequested: () => ref.read(syncUiStateProvider.notifier).syncNow(),
      isTabletOrderRecord: (record) => isTabletOrderPayload(
        record: record,
        localDeviceId: localDeviceId,
      ),
      onTabletOrderInserted: ({
        required orderId,
        required orderNumber,
        required record,
      }) {
        ref
            .read(tabletOrderArrivalControllerProvider.notifier)
            .onOrderDetected(orderId: orderId, orderNumber: orderNumber);
        ref.read(routerProvider).go(DesktopFeatures.tabletOrdersRoute);
        ref
            .read(tabletOrderAutoPrintServiceProvider)
            .onMobileOrderDetected(orderId)
            .ignore();
        ref.read(notificationControllerProvider.notifier).showMobileOrderPlaced(
              orderId: orderId,
              orderNumber: orderNumber,
            );
        ref.read(syncUiStateProvider.notifier).syncNow().ignore();
      },
    )..start();

    ref.read(syncUiStateProvider.notifier).syncNow().ignore();
  }

  Future<void> _stopRealtimeListener() async {
    final listener = _orderRealtimeListener;
    _orderRealtimeListener = null;
    if (listener != null) {
      await listener.dispose();
    }
  }

  void _onSyncFinished(SyncUiState? previous, SyncUiState next) {
    if (previous?.runState == SyncRunState.syncing &&
        next.runState == SyncRunState.idle) {
      ref.read(tabletOrderAutoPrintServiceProvider).processAfterSync().ignore();
      ref.read(creditOrderChargeProcessorProvider).processAfterSync().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status == next.status && previous?.user?.id == next.user?.id) {
        return;
      }
      _syncRealtimeWithAuth(next).ignore();
    });
    ref.listen<SyncUiState>(syncUiStateProvider, _onSyncFinished);

    return widget.child;
  }
}

