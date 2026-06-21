import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads secrets from `.env` at project root (gitignored).
///
/// Falls back to bundled `.env.example` placeholders when `.env` is missing.
abstract final class EnvConfig {
  static const _supabaseUrlKey = 'SUPABASE_URL';
  static const _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  static Future<void> load() async {
    var loadedFrom = 'none';

    if (await _tryLoadFile(File('.env'))) {
      loadedFrom = '.env';
    } else if (await _tryLoadBundledExample()) {
      loadedFrom = '.env.example (bundled fallback)';
    }

    if (isSupabaseConfigured) {
      debugPrint('EnvConfig: Supabase credentials loaded from $loadedFrom');
    } else if (loadedFrom != 'none') {
      debugPrint(
        'EnvConfig: loaded $loadedFrom but Supabase keys are missing or '
        'still placeholders — copy .env.example to .env and add real values',
      );
    } else {
      debugPrint(
        'EnvConfig: no env file found — app runs offline-only. '
        'Copy .env.example to .env in the project root.',
      );
    }
  }

  static Future<bool> _tryLoadFile(File file) async {
    if (!await file.exists()) return false;
    dotenv.testLoad(fileInput: await file.readAsString());
    return true;
  }

  static Future<bool> _tryLoadBundledExample() async {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String get supabaseUrl =>
      dotenv.env[_supabaseUrlKey]?.trim() ?? '';

  static String get supabaseAnonKey =>
      dotenv.env[_supabaseAnonKeyKey]?.trim() ?? '';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-ref') &&
      supabaseAnonKey != 'your-supabase-anon-key';
}
