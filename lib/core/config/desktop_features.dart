/// Desktop shell feature toggles.
///
/// POS and dashboard routes remain registered but are hidden from navigation
/// while [hidePosAndDashboard] is enabled.
abstract final class DesktopFeatures {
  /// When true, the desktop app acts as a tablet-order monitor + print hub.
  static const hidePosAndDashboard = true;

  static const String tabletOrdersRoute = '/tablet-orders';

  static String get homeRoute =>
      hidePosAndDashboard ? tabletOrdersRoute : '/dashboard';

  static bool get showPosAndDashboard => !hidePosAndDashboard;
}
