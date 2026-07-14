import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

/// Plays an attention sound for newly received live orders (Windows desktop).
///
/// Uses Windows multimedia APIs (no Flutter audio plugin):
/// - MP3 via MCI (`assets/sounds/order_alert.mp3` if present)
/// - WAV via `PlaySound` (`assets/sounds/order_alert.wav` bundled default)
///
/// Falls back to [SystemSoundType.alert] when native playback is unavailable.
abstract final class OrderNotificationSound {
  static const mp3AssetPath = 'assets/sounds/order_alert.mp3';
  static const wavAssetPath = 'assets/sounds/order_alert.wav';
  static const _mciAlias = 'restaurix_order_alert';

  static String? _cachedFilePath;
  static bool? _isMp3;

  static Future<void> play() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        final path = await _ensureLocalSoundFile();
        if (path != null) {
          final played = _isMp3 == true
              ? _playMp3WithMci(path)
              : _playWavWithPlaySound(path);
          if (played) return;
        }
      }

      await _playSystemFallback();
    } catch (_) {
      try {
        await _playSystemFallback();
      } catch (_) {}
    }
  }

  static void playFireAndForget() {
    unawaited(play());
  }

  static Future<void> _playSystemFallback() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    await SystemSound.play(SystemSoundType.alert);
  }

  static Future<String?> _ensureLocalSoundFile() async {
    if (_cachedFilePath != null && File(_cachedFilePath!).existsSync()) {
      return _cachedFilePath;
    }

    for (final entry in [
      (mp3AssetPath, true),
      (wavAssetPath, false),
    ]) {
      final assetPath = entry.$1;
      final isMp3 = entry.$2;
      try {
        final data = await rootBundle.load(assetPath);
        final dir = await getTemporaryDirectory();
        final ext = isMp3 ? 'mp3' : 'wav';
        final file = File('${dir.path}${Platform.pathSeparator}order_alert.$ext');
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        _cachedFilePath = file.path;
        _isMp3 = isMp3;
        return file.path;
      } catch (_) {
        // Try next asset.
      }
    }
    return null;
  }

  static bool _playWavWithPlaySound(String path) {
    final pszSound = path.toNativeUtf16();
    try {
      final ok = PlaySound(
        pszSound,
        NULL,
        SND_ASYNC | SND_FILENAME | SND_NODEFAULT,
      );
      return ok != 0;
    } finally {
      free(pszSound);
    }
  }

  static bool _playMp3WithMci(String path) {
    // Escape quotes in path for the MCI command string.
    final safePath = path.replaceAll('"', r'\"');
    _mci('close $_mciAlias');
    final openResult = _mci(
      'open "$safePath" type mpegvideo alias $_mciAlias',
    );
    if (openResult != 0) {
      // Some systems prefer mpegvideo without type, or digitalvideo.
      final retry = _mci('open "$safePath" alias $_mciAlias');
      if (retry != 0) return false;
    }
    final playResult = _mci('play $_mciAlias');
    return playResult == 0;
  }

  static int _mci(String command) {
    final cmd = command.toNativeUtf16();
    try {
      return mciSendString(cmd, nullptr, 0, NULL);
    } finally {
      free(cmd);
    }
  }
}
