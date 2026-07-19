/// Order total from persisted pricing fields (discounts then surcharges).
double computeOrderTotal({
  required double subtotal,
  required double itemDiscountTotal,
  required double orderDiscountTotal,
  double serviceCharge = 0,
  double deliveryCharge = 0,
}) {
  final net = subtotal -
      itemDiscountTotal -
      orderDiscountTotal +
      serviceCharge +
      deliveryCharge;
  return net < 0 ? 0 : net;
}
