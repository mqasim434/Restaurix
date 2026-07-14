import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../branding/app_brand.dart';

/// Loads and prepares [AppBrand.logoAsset] for ESC/POS thermal printing.
abstract final class EscPosLogo {
  /// Target width in dots for 80 mm printers (~203 dpi usable area).
  static const int printWidthDots = 384;

  static Future<img.Image?> loadForThermal({
    int maxWidth = printWidthDots,
  }) async {
    try {
      final data = await rootBundle.load(AppBrand.logoAsset);
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) return null;

      final prepared = _prepareForThermal(decoded);
      if (prepared.width <= maxWidth) return prepared;

      return img.copyResize(
        prepared,
        width: maxWidth,
        interpolation: img.Interpolation.average,
      );
    } catch (_) {
      return null;
    }
  }

  static List<int> bytes(Generator generator, img.Image logo) {
    return generator.image(logo, align: PosAlign.center);
  }

  /// Black background → white paper; colored logo → solid black print dots.
  static img.Image _prepareForThermal(img.Image source) {
    final out = img.Image(width: source.width, height: source.height);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        // Transparent or near-black background → white (no ink).
        final isBackground = a < 32 || (r < 40 && g < 40 && b < 40);
        if (isBackground) {
          out.setPixelRgba(x, y, 255, 255, 255, 255);
          continue;
        }

        // Logo colors (maroon/gold/white accents) → black ink.
        out.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }

    return out;
  }
}
