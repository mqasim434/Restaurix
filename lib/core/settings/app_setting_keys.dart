/// Known keys for [AppSettingIsar].
abstract final class AppSettingKeys {
  static const businessName = 'business.name';
  static const businessAddress = 'business.address';
  static const receiptHeaderText = 'receipt.header_text';
  static const receiptFooterText = 'receipt.footer_text';

  /// Customer receipt printer — config id or raw Windows name / IP.
  static const receiptPrinterId = 'receipt.printer_id';

  /// Fallback kitchen printer — config id or raw target.
  static const kitchenDefaultPrinterId = 'kitchen.default_printer_id';

  /// JSON array of [PrinterConfig].
  static const printerConfigs = 'printers.configs';

  /// JSON map of kitchen category label -> printer config id or raw target.
  static const kitchenCategoryPrinterMap = 'kitchen.category_printer_map';

  static const salaryGenerationDay = 'salary.generation_day';
  static const salaryLastAutoPeriodEnd = 'salary.last_auto_period_end';

  static const syncLastSuccessfulAt = 'sync.last_successful_at';
  static const syncConflictLog = 'sync.conflict_log';
  static const syncEntityCursorPrefix = 'sync.cursor';

  /// JSON-encoded [AppUser] for offline session restore.
  static const authCachedSession = 'auth.cached_session';
}
