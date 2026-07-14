import '../models/order_enums.dart';

OrderPaymentStatus resolvePaymentStatus({required bool isPrepaid}) {
  return isPrepaid ? OrderPaymentStatus.paid : OrderPaymentStatus.unpaid;
}

bool resolveIsPrepaid({
  required OrderType orderType,
  bool? override,
}) {
  return override ?? orderType.defaultIsPrepaid;
}
