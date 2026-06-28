/// Known keys for [AppSettingIsar].
abstract final class AppSettingKeys {
  /// Fallback kitchen printer target when a product has no printer ID.
  static const kitchenDefaultPrinterId = 'kitchen.default_printer_id';

  /// Customer receipt printer — Windows name or network IP/IP:port.
  static const receiptPrinterId = 'receipt.printer_id';

  /// Business name shown on customer receipts (Module 29 Settings UI).
  static const businessName = 'business.name';

  /// Day of month (1–28) when prior-period salary slips auto-generate.
  static const salaryGenerationDay = 'salary.generation_day';

  /// ISO date of the last auto-generated salary slip period end.
  static const salaryLastAutoPeriodEnd = 'salary.last_auto_period_end';
}
