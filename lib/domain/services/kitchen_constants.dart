import '../../core/constants.dart';

/// Kitchen prep timing defaults and stage split rules.
abstract final class KitchenConstants {
  static const defaultPrepMinutes = AppConstants.defaultProductPrepMinutes;

  /// Incoming column duration as a fraction of total prep time.
  static const incomingStageFraction = 0.25;

  static const minStageMinutes = 1;
}
