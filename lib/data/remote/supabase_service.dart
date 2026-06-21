import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';
import '../../core/remote/supabase_table_names.dart';

/// Initializes and exposes the Supabase client.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!EnvConfig.isSupabaseConfigured) {
      debugPrint(
        'Supabase: skipped initialization — set SUPABASE_URL and '
        'SUPABASE_ANON_KEY in .env',
      );
      return;
    }

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not initialized. Add credentials to .env and restart.',
      );
    }
    return Supabase.instance.client;
  }

  /// Non-blocking connectivity check after [initialize].
  static void pingInBackground() {
    if (!isInitialized) return;
    pingSupabaseInBackground(Supabase.instance.client);
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService._();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return ref.watch(supabaseServiceProvider).client;
});

/// Non-blocking connectivity check — logs result, never blocks UI.
Future<void> pingSupabase(SupabaseClient client) async {
  if (!EnvConfig.isSupabaseConfigured) {
    debugPrint('Supabase ping: skipped (.env not configured)');
    return;
  }

  try {
    await client
        .from(SupabaseTableNames.categories)
        .select('id')
        .limit(1)
        .maybeSingle();
    debugPrint('Supabase ping: success');
  } catch (error) {
    debugPrint('Supabase ping: failed ($error)');
  }
}

/// Fires [pingSupabase] without awaiting — safe to call during app startup.
void pingSupabaseInBackground(SupabaseClient client) {
  pingSupabase(client).ignore();
}
