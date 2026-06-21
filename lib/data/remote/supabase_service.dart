import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

/// Initializes and exposes the Supabase client.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService._();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return ref.watch(supabaseServiceProvider).client;
});

/// Non-blocking connectivity check logged at startup (Module 3 expands this).
Future<void> pingSupabase(SupabaseClient client) async {
  try {
    await client.from('_ping').select().limit(1).maybeSingle();
    debugPrint('Supabase ping: success');
  } catch (error) {
    debugPrint('Supabase ping: failed ($error)');
  }
}
