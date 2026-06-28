import 'package:flutter/material.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../kitchen_ticket/kitchen_ticket_data.dart';

void showKitchenPrintFeedback(
  BuildContext context,
  KitchenTicketPrintResult result, {
  String? successMessage,
}) {
  if (result.anyPrinted && successMessage != null && !result.hasWarnings) {
    AppSnackbar.success(context, successMessage);
    return;
  }

  if (result.hasWarnings) {
    AppSnackbar.info(context, result.warnings.join('\n'));
    return;
  }

  if (successMessage != null && result.anyPrinted) {
    AppSnackbar.success(context, successMessage);
  }
}
