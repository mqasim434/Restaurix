import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// Fixes [CERTIFICATE_VERIFY_FAILED] on Windows when Dart cannot read the
/// system root CA store (common on fresh or locked-down PCs).
///
/// Supabase (*.supabase.co) is signed by Google Trust Services (WE1).
abstract final class WindowsTls {
  static Client? _supabaseHttpClient;

  static const _rootAssets = [
    'assets/certs/gts-root-r1.pem',
    'assets/certs/gts-root-r4.pem',
  ];

  static Future<void> configure() async {
    if (!Platform.isWindows) return;

    final context = await _buildSecurityContext();
    final overrides = _WindowsHttpOverrides(context);
    HttpOverrides.global = overrides;
    _supabaseHttpClient = IOClient(overrides.createTrustedClient());
    debugPrint('WindowsTls: installed bundled Google Trust Services roots');
  }

  static Client? get supabaseHttpClient => _supabaseHttpClient;

  static Future<SecurityContext> _buildSecurityContext() async {
    final context = SecurityContext.defaultContext;
    for (final asset in _rootAssets) {
      try {
        final raw = await rootBundle.load(asset);
        context.setTrustedCertificatesBytes(
          raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
        );
      } catch (error) {
        debugPrint('WindowsTls: could not load $asset ($error)');
      }
    }
    return context;
  }
}

class _WindowsHttpOverrides extends HttpOverrides {
  _WindowsHttpOverrides(this._context);

  final SecurityContext _context;

  HttpClient createTrustedClient() {
    return super.createHttpClient(_context)
      ..connectionTimeout = const Duration(seconds: 30);
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context ?? _context)
      ..connectionTimeout = const Duration(seconds: 30);
  }
}
