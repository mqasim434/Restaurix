import '../models/order.dart';
import '../models/order_enums.dart';
import '../models/user_role.dart';

enum OrderActionType {
  advance,
  markPaid,
  cancel,
  editInPos,
  hold,
  resume,
}

class OrderAction {
  const OrderAction({
    required this.type,
    required this.label,
    this.nextStatus,
  });

  final OrderActionType type;
  final String label;
  final OrderStatus? nextStatus;
}

class OrderLifecycleException implements Exception {
  OrderLifecycleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Status progression and permission rules for order management.
abstract final class OrderLifecycle {
  static bool canEdit(Order order, UserRole role) {
    if (order.status.isClosed) return false;
    if (order.paymentStatus.isSettled) return false;
    return role == UserRole.admin || role == UserRole.salesman;
  }

  static String? editBlockedReason(Order order) {
    if (order.status == OrderStatus.cancelled) {
      return 'Cancelled orders cannot be edited.';
    }
    if (order.status == OrderStatus.completed) {
      return 'Completed orders cannot be edited.';
    }
    if (order.paymentStatus.isSettled) {
      return 'This order has been paid and is read-only. Only status progression is allowed.';
    }
    return null;
  }

  static bool canCancel(Order order, UserRole role) {
    if (order.status.isClosed) return false;
    return role == UserRole.admin;
  }

  static OrderStatus? nextStatus(Order order) {
    if (order.status.isClosed) return null;

    return switch (order.status) {
      OrderStatus.received ||
      OrderStatus.preparing ||
      OrderStatus.ready =>
        switch (order.orderType) {
          OrderType.dineIn => OrderStatus.served,
          _ => order.paymentStatus.isSettled ||
                  order.isPrepaid ||
                  order.paymentType == PaymentType.credit
              ? OrderStatus.completed
              : OrderStatus.paid,
        },
      OrderStatus.served => order.paymentStatus.isSettled ||
              order.paymentType == PaymentType.credit
          ? OrderStatus.completed
          : OrderStatus.paid,
      OrderStatus.paid => OrderStatus.completed,
      OrderStatus.completed || OrderStatus.cancelled => null,
    };
  }

  static String advanceLabel(Order order) {
    final next = nextStatus(order);
    if (next == null) return 'Advance';
    return switch (next) {
      OrderStatus.served => 'Mark Served',
      OrderStatus.paid => 'Mark Paid',
      OrderStatus.completed => 'Complete Order',
      _ => 'Advance',
    };
  }

  static bool canAdvance(Order order, UserRole role) {
    final next = nextStatus(order);
    if (next == null) return false;

    if (role == UserRole.admin) return true;

    return switch (next) {
      OrderStatus.served => order.orderType == OrderType.dineIn,
      _ => false,
    };
  }

  static bool canMarkPaid(Order order, UserRole role) {
    if (order.paymentType == PaymentType.credit) return false;
    if (role != UserRole.admin) return false;
    if (order.status.isClosed) return false;
    if (order.paymentStatus.isSettled) return false;
    return order.status == OrderStatus.served ||
        (order.status == OrderStatus.received &&
            order.orderType != OrderType.dineIn);
  }

  static bool canHold(Order order, UserRole role) {
    if (order.status.isClosed) return false;
    if (order.isHeld) return false;
    return role == UserRole.admin || role == UserRole.salesman;
  }

  static bool canResume(Order order, UserRole role) {
    if (!order.isHeld) return false;
    if (order.status.isClosed) return false;
    return role == UserRole.admin || role == UserRole.salesman;
  }

  static List<OrderAction> availableActions(Order order, UserRole role) {
    final actions = <OrderAction>[];

    if (canEdit(order, role)) {
      actions.add(
        const OrderAction(
          type: OrderActionType.editInPos,
          label: 'Edit in POS',
        ),
      );
    }

    if (canAdvance(order, role)) {
      actions.add(
        OrderAction(
          type: OrderActionType.advance,
          label: advanceLabel(order),
          nextStatus: nextStatus(order),
        ),
      );
    }

    if (canCancel(order, role)) {
      actions.add(
        const OrderAction(
          type: OrderActionType.cancel,
          label: 'Cancel Order',
        ),
      );
    }

    if (canHold(order, role)) {
      actions.add(
        const OrderAction(
          type: OrderActionType.hold,
          label: 'Hold Order',
        ),
      );
    }

    if (canResume(order, role)) {
      actions.add(
        const OrderAction(
          type: OrderActionType.resume,
          label: 'Resume Order',
        ),
      );
    }

    return actions;
  }

  static void validateTransition({
    required Order order,
    required OrderStatus target,
    required UserRole role,
  }) {
    if (order.status.isClosed) {
      throw OrderLifecycleException('Order is already closed');
    }

    final expected = nextStatus(order);
    if (target == OrderStatus.paid && canMarkPaid(order, role)) {
      return;
    }

    if (expected != target) {
      throw OrderLifecycleException(
        'Cannot move from ${order.status.name} to ${target.name}',
      );
    }

    if (!canAdvance(order, role) && target != OrderStatus.paid) {
      throw OrderLifecycleException('You do not have permission for this action');
    }
  }
}

extension OrderStatusLabelX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.received => 'Received',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.served => 'Served',
        OrderStatus.paid => 'Paid',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };
}

extension OrderPaymentStatusLabelX on OrderPaymentStatus {
  String get label => switch (this) {
        OrderPaymentStatus.unpaid => 'Unpaid',
        OrderPaymentStatus.paid => 'Paid',
        OrderPaymentStatus.refunded => 'Refunded',
      };
}
