import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../services/order_notification_sound.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.orderId,
    required this.createdAt,
    this.isMobileOrder = false,
  });

  final String id;
  final String title;
  final String message;
  final String? orderId;
  final DateTime createdAt;
  final bool isMobileOrder;
}

/// In-app notification queue (mobile order alerts).
class NotificationController extends StateNotifier<List<AppNotification>> {
  NotificationController({
    void Function()? playSound,
  })  : _playSound = playSound ?? OrderNotificationSound.playFireAndForget,
        super(const []);

  final void Function() _playSound;
  final _autoDismissTimers = <String, Timer>{};

  void showMobileOrderPlaced({
    required String orderId,
    required String orderNumber,
  }) {
    if (state.any((n) => n.orderId == orderId)) return;

    final notification = AppNotification(
      id: const Uuid().v4(),
      title: 'New order received',
      message: '$orderNumber was placed and is ready on Live Orders.',
      orderId: orderId,
      createdAt: DateTime.now(),
      isMobileOrder: true,
    );

    state = [notification, ...state].take(5).toList();
    _scheduleAutoDismiss(notification.id);
    _playSound();
  }

  void dismiss(String id) {
    _autoDismissTimers.remove(id)?.cancel();
    state = state.where((notification) => notification.id != id).toList();
  }

  void clearAll() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
    state = const [];
  }

  void _scheduleAutoDismiss(String id) {
    _autoDismissTimers[id]?.cancel();
    _autoDismissTimers[id] = Timer(const Duration(seconds: 10), () {
      dismiss(id);
    });
  }

  @override
  void dispose() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
    super.dispose();
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, List<AppNotification>>(
  (ref) => NotificationController(),
);

final unreadMobileOrderNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationControllerProvider)
      .where((notification) => notification.isMobileOrder)
      .length;
});
