/// Known keys for [AppSettingIsar].
abstract final class AppSettingKeys {
  static const businessName = 'business.name';
  static const businessAddress = 'business.address';
  static const receiptHeaderText = 'receipt.header_text';
  static const receiptFooterText = 'receipt.footer_text';
  static const currencyCode = 'business.currency_code';

  static const salaryGenerationDay = 'salary.generation_day';
  static const salaryLastAutoPeriodEnd = 'salary.last_auto_period_end';

  static const syncLastSuccessfulAt = 'sync.last_successful_at';
  static const syncConflictLog = 'sync.conflict_log';
  static const syncEntityCursorPrefix = 'sync.cursor';

  static const authCachedSession = 'auth.cached_session';

  /// JSON array of tablet order IDs whose slips were auto-printed on desktop.
  static const tabletOrdersPrintedSlipIds = 'tablet_orders.printed_slip_ids';
}
