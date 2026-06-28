import 'package:flutter/material.dart';

import '../../../core/widgets/app_snackbar.dart';
import 'receipt_data.dart';

void showReceiptPrintFeedback(
  BuildContext context,
  ReceiptPrintResult result, {
  String? successMessage,
}) {
  if (result.printed && successMessage != null && !result.hasWarnings) {
    AppSnackbar.success(context, successMessage);
    return;
  }

  if (result.hasWarnings) {
    AppSnackbar.info(context, result.warnings.join('\n'));
    return;
  }

  if (successMessage != null && result.printed) {
    AppSnackbar.success(context, successMessage);
  }
}
