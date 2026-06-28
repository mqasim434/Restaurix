import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/env_config.dart';
import '../../data/remote/supabase_service.dart';

/// Tracks whether the device has a usable network route for sync attempts.
class SyncConnectivityService {
  SyncConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> watchOnline() async* {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      yield false;
      return;
    }

    yield await isOnline();
    await for (final results in _connectivity.onConnectivityChanged) {
      yield _hasNetworkRoute(results);
    }
  }

  Future<bool> isOnline() async {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      return false;
    }
    final results = await _connectivity.checkConnectivity();
    return _hasNetworkRoute(results);
  }

  bool _hasNetworkRoute(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );
  }
}

class SyncCoordinator {
  SyncCoordinator({
    required SyncConnectivityService connectivity,
    required Future<void> Function() triggerSync,
    Duration interval = const Duration(minutes: 3),
  })  : _connectivity = connectivity,
        _triggerSync = triggerSync,
        _interval = interval;

  final SyncConnectivityService _connectivity;
  final Future<void> Function() _triggerSync;
  final Duration _interval;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _intervalTimer;
  var _wasOffline = true;

  Future<void> start() async {
    if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
      debugPrint('SyncCoordinator: disabled — Supabase not configured');
      return;
    }

    _wasOffline = !(await _connectivity.isOnline());
    _connectivitySub = _connectivity.watchOnline().listen((online) async {
      if (online && _wasOffline) {
        await _triggerSync();
      }
      _wasOffline = !online;
    });

    _intervalTimer = Timer.periodic(_interval, (_) async {
      if (await _connectivity.isOnline()) {
        await _triggerSync();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _intervalTimer?.cancel();
  }
}
