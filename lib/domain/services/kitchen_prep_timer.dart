import '../models/kitchen_board.dart';
import '../models/order_enums.dart';
import '../models/order_item.dart';
import 'kitchen_constants.dart';
import 'kitchen_lifecycle.dart';

/// Computes per-stage durations and due times for automatic kitchen advancement.
abstract final class KitchenPrepTimer {
  static int incomingStageMinutes(int prepMinutes) {
    final total = prepMinutes.clamp(1, 999);
    if (total == 1) return 1;

    final scaled =
        (total * KitchenConstants.incomingStageFraction).round();
    final upper = total - 1;
    final lower = KitchenConstants.minStageMinutes;
    final minBound = lower <= upper ? lower : upper;
    return scaled.clamp(minBound, upper).clamp(1, total);
  }

  static int preparingStageMinutes(int prepMinutes) {
    final total = prepMinutes.clamp(1, 999);
    return total - incomingStageMinutes(total);
  }

  static int stageDurationMinutes(KitchenStatus status, int prepMinutes) {
    return switch (status) {
      KitchenStatus.received => incomingStageMinutes(prepMinutes),
      KitchenStatus.preparing => preparingStageMinutes(prepMinutes),
      KitchenStatus.ready || KitchenStatus.served => 0,
    };
  }

  static KitchenStatus? dueAdvanceStatus({
    required OrderItem item,
    required DateTime now,
    required bool orderIsHeld,
  }) {
    if (orderIsHeld) return null;
    if (!KitchenLifecycle.isItemVisibleOnKitchen(item)) return null;

    final stageMinutes =
        stageDurationMinutes(item.kitchenStatus, item.prepMinutes);
    if (stageMinutes <= 0) return null;

    final elapsed = now.difference(item.kitchenStatusChangedAt);
    if (elapsed.inSeconds >= stageMinutes * 60) {
      return KitchenLifecycle.nextItemStatus(item.kitchenStatus);
    }
    return null;
  }

  static Duration remainingInStage({
    required OrderItem item,
    required DateTime now,
  }) {
    return _remainingInStage(
      status: item.kitchenStatus,
      prepMinutes: item.prepMinutes,
      statusChangedAt: item.kitchenStatusChangedAt,
      now: now,
    );
  }

  static Duration remainingForDisplayItem({
    required KitchenDisplayItem item,
    required DateTime now,
  }) {
    return _remainingInStage(
      status: item.kitchenStatus,
      prepMinutes: item.prepMinutes,
      statusChangedAt: item.kitchenStatusChangedAt,
      now: now,
    );
  }

  static double stageProgress({
    required OrderItem item,
    required DateTime now,
  }) {
    return _stageProgress(
      status: item.kitchenStatus,
      prepMinutes: item.prepMinutes,
      statusChangedAt: item.kitchenStatusChangedAt,
      now: now,
    );
  }

  static double displayStageProgress({
    required KitchenDisplayItem item,
    required DateTime now,
  }) {
    return _stageProgress(
      status: item.kitchenStatus,
      prepMinutes: item.prepMinutes,
      statusChangedAt: item.kitchenStatusChangedAt,
      now: now,
    );
  }

  static Duration _remainingInStage({
    required KitchenStatus status,
    required int prepMinutes,
    required DateTime statusChangedAt,
    required DateTime now,
  }) {
    final stageMinutes = stageDurationMinutes(status, prepMinutes);
    final deadline =
        statusChangedAt.add(Duration(minutes: stageMinutes));
    final remaining = deadline.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static double _stageProgress({
    required KitchenStatus status,
    required int prepMinutes,
    required DateTime statusChangedAt,
    required DateTime now,
  }) {
    final stageMinutes = stageDurationMinutes(status, prepMinutes);
    if (stageMinutes <= 0) return 1;

    final elapsed = now.difference(statusChangedAt).inSeconds;
    return (elapsed / (stageMinutes * 60)).clamp(0.0, 1.0);
  }

  static String formatRemaining(Duration remaining) {
    final totalSeconds = remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }
}
