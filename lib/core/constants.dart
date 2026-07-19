/// Application-wide constants (non-secret).
abstract final class AppConstants {
  static const String appName = 'Restaurix';
  static const int defaultProductPrepMinutes = 10;

  /// Fallback when no business name is stored in settings.
  static const String defaultBusinessName = 'Bin Omran';

  /// Printed under the receipt logo when no phone is configured.
  static const String defaultBusinessPhone = '+974 31241644';

  /// Printed under the receipt logo when no address is configured.
  static const String defaultBusinessAddress =
      'St 850, Zone 37, Ibn Omran Street, Doha, Qatar';
}
