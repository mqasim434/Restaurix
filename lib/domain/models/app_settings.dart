import '../../core/constants.dart';
import 'app_currency.dart';

class AppSettings {
  const AppSettings({
    required this.businessName,
    this.businessAddress,
    this.receiptHeaderText,
    this.receiptFooterText,
    this.currencyCode = AppCurrency.defaultCode,
    this.salaryGenerationDay = 1,
  });

  final String businessName;
  final String? businessAddress;
  final String? receiptHeaderText;
  final String? receiptFooterText;
  final String currencyCode;
  final int salaryGenerationDay;

  static const defaults = AppSettings(
    businessName: AppConstants.defaultBusinessName,
    businessAddress: AppConstants.defaultBusinessAddress,
    currencyCode: AppCurrency.defaultCode,
    salaryGenerationDay: 1,
  );

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    bool clearBusinessAddress = false,
    String? receiptHeaderText,
    bool clearReceiptHeaderText = false,
    String? receiptFooterText,
    bool clearReceiptFooterText = false,
    String? currencyCode,
    int? salaryGenerationDay,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress:
          clearBusinessAddress ? null : (businessAddress ?? this.businessAddress),
      receiptHeaderText: clearReceiptHeaderText
          ? null
          : (receiptHeaderText ?? this.receiptHeaderText),
      receiptFooterText: clearReceiptFooterText
          ? null
          : (receiptFooterText ?? this.receiptFooterText),
      currencyCode: currencyCode ?? this.currencyCode,
      salaryGenerationDay: salaryGenerationDay ?? this.salaryGenerationDay,
    );
  }
}

int parseSalaryGenerationDay(String? raw) {
  final parsed = int.tryParse(raw ?? '');
  if (parsed == null) return AppSettings.defaults.salaryGenerationDay;
  return parsed.clamp(1, 28);
}
