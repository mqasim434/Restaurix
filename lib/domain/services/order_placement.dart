import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/order_enums.dart';

/// Generates collision-resistant order numbers for offline multi-device use.
String generateOrderNumber({
  required String deviceId,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  final devicePrefix =
      deviceId.replaceAll('-', '').substring(0, 6).toUpperCase();
  final datePart = DateFormat('yyyyMMdd').format(timestamp);
  final uniquePart =
      const Uuid().v4().replaceAll('-', '').substring(0, 6).toUpperCase();
  return '$devicePrefix-$datePart-$uniquePart';
}

OrderPaymentStatus resolvePaymentStatus({required bool isPrepaid}) {
  return isPrepaid ? OrderPaymentStatus.paid : OrderPaymentStatus.unpaid;
}

bool resolveIsPrepaid({
  required OrderType orderType,
  bool? override,
}) {
  return override ?? orderType.defaultIsPrepaid;
}
