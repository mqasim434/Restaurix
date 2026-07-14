import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/features/notifications/providers/notification_providers.dart';

void main() {
  test('NotificationController deduplicates mobile order alerts', () {
    var soundPlays = 0;
    final controller = NotificationController(
      playSound: () => soundPlays++,
    );

    controller.showMobileOrderPlaced(
      orderId: 'order-1',
      orderNumber: 'ODR-0001',
    );
    controller.showMobileOrderPlaced(
      orderId: 'order-1',
      orderNumber: 'ODR-0001',
    );

    expect(controller.state, hasLength(1));
    expect(controller.state.first.orderId, 'order-1');
    expect(controller.state.first.message, contains('ODR-0001'));
    expect(soundPlays, 1);

    controller.dispose();
  });
}
