import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// Loads Supabase / ImageKit credentials from `.env` on disk (not bundled secrets).
abstract final class EnvConfig {
  static const _supabaseUrlKey = 'SUPABASE_URL';
  static const _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const _imageKitPublicKeyKey = 'IMAGEKIT_PUBLIC_KEY';
  static const _imageKitPrivateKeyKey = 'IMAGEKIT_PRIVATE_KEY';
  static const _imageKitUrlEndpointKey = 'IMAGEKIT_URL_ENDPOINT';

  static String? _loadedFromPath;

  /// Where credentials were loaded from, if any.
  static String? get loadedFromPath => _loadedFromPath;

  static Future<void> load() async {
    _loadedFromPath = null;

    for (final file in await _envFileCandidates()) {
      if (await _tryLoadFile(file)) {
        _loadedFromPath = file.path;
        break;
      }
    }

    if (!dotenv.isInitialized && await _tryLoadBundledExample()) {
      _loadedFromPath = '.env.example (bundled placeholder)';
    }

    if (isSupabaseConfigured) {
      debugPrint('EnvConfig: Supabase credentials loaded from $_loadedFromPath');
      return;
    }

    if (_loadedFromPath != null) {
      debugPrint(
        'EnvConfig: loaded $_loadedFromPath but Supabase keys are missing or '
        'still placeholders',
      );
    } else {
      debugPrint('EnvConfig: no .env file found — app runs offline-only');
    }
    debugPrint('EnvConfig: ${deploymentHint()}');
  }

  /// Checked in order: dev project root, folder with the .exe, app data.
  static Future<List<File>> _envFileCandidates() async {
    final files = <File>[];

    files.add(File('.env'));

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final exeFile = File(Platform.resolvedExecutable);
      files.add(File('${exeFile.parent.path}${Platform.pathSeparator}.env'));
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      files.add(
        File('${supportDir.path}${Platform.pathSeparator}.env'),
      );
    } catch (_) {}

    return files;
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

  static String _envValue(String key) {
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key]?.trim() ?? '';
  }

  static String get supabaseUrl => _envValue(_supabaseUrlKey);

  static String get supabaseAnonKey => _envValue(_supabaseAnonKeyKey);

  static String get imageKitPublicKey => _envValue(_imageKitPublicKeyKey);

  static String get imageKitPrivateKey => _envValue(_imageKitPrivateKeyKey);

  static String get imageKitUrlEndpoint => _envValue(_imageKitUrlEndpointKey);

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-ref') &&
      supabaseAnonKey != 'your-supabase-anon-key';

  /// Private key + URL endpoint required for desktop uploads to ImageKit.
  static bool get isImageKitConfigured =>
      imageKitPrivateKey.isNotEmpty &&
      imageKitUrlEndpoint.isNotEmpty &&
      !imageKitPrivateKey.contains('your_private') &&
      !imageKitUrlEndpoint.contains('your_imagekit_id');

  static String deploymentHint() {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return 'Create a file named .env next to restaurix.exe with '
          'SUPABASE_URL, SUPABASE_ANON_KEY, and ImageKit keys. '
          'Example: $exeDir\\.env';
    }
    return 'Create a .env file next to the app executable with '
        'SUPABASE_URL, SUPABASE_ANON_KEY, and ImageKit keys.';
  }
}
