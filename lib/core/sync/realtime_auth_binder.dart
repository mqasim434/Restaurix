import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/supabase_service.dart';

/// Applies the current Supabase Auth JWT to the Realtime client.
///
/// Without this, Postgres Changes events are filtered by RLS and the desktop
/// receives no order inserts even when Realtime is enabled in the database.
abstract final class RealtimeAuthBinder {
  static Future<void> applySession() async {
    if (!SupabaseService.isInitialized) return;

    final client = Supabase.instance.client;
    final token = client.auth.currentSession?.accessToken;

    if (token == null) {
      await client.realtime.setAuth(null);
      debugPrint('RealtimeAuthBinder: cleared — no active session');
      return;
    }

    await client.realtime.setAuth(token);
    debugPrint('RealtimeAuthBinder: session JWT applied for Realtime');
  }
}
