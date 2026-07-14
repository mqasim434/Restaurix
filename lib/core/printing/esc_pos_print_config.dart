import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Thermal printer typography — Font A for clear, readable text on 80 mm paper.
///
/// Font B is condensed/smaller and often looks muddy on cheap printers.
/// Font A (12×24) is the standard clear face for both body and headers.
abstract final class EscPosPrintConfig {
  static const bodyFont = PosFontType.fontA;
  static const headerFont = PosFontType.fontA;
}
