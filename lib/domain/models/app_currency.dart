/// Supported display currencies — ISO 4217 code stored in settings.
class AppCurrencyOption {
  const AppCurrencyOption({
    required this.code,
    required this.label,
    required this.locale,
    required this.symbol,
    this.decimalDigits = 2,
  });

  final String code;
  final String label;
  final String locale;
  final String symbol;
  final int decimalDigits;
}

abstract final class AppCurrency {
  static const defaultCode = 'USD';

  static const options = <AppCurrencyOption>[
    AppCurrencyOption(
      code: 'USD',
      label: 'US Dollar (USD)',
      locale: 'en_US',
      symbol: r'$',
    ),
    AppCurrencyOption(
      code: 'PKR',
      label: 'Pakistani Rupee (PKR)',
      locale: 'en_PK',
      symbol: 'Rs',
    ),
    AppCurrencyOption(
      code: 'EUR',
      label: 'Euro (EUR)',
      locale: 'de_DE',
      symbol: '€',
    ),
    AppCurrencyOption(
      code: 'GBP',
      label: 'British Pound (GBP)',
      locale: 'en_GB',
      symbol: '£',
    ),
    AppCurrencyOption(
      code: 'AED',
      label: 'UAE Dirham (AED)',
      locale: 'ar_AE',
      symbol: 'AED ',
    ),
    AppCurrencyOption(
      code: 'SAR',
      label: 'Saudi Riyal (SAR)',
      locale: 'ar_SA',
      symbol: 'SAR ',
    ),
    AppCurrencyOption(
      code: 'QAR',
      label: 'Qatari Riyal (QAR)',
      locale: 'en_QA',
      symbol: 'QAR ',
    ),
    AppCurrencyOption(
      code: 'INR',
      label: 'Indian Rupee (INR)',
      locale: 'en_IN',
      symbol: '₹',
    ),
    AppCurrencyOption(
      code: 'CAD',
      label: 'Canadian Dollar (CAD)',
      locale: 'en_CA',
      symbol: r'CA$',
    ),
    AppCurrencyOption(
      code: 'AUD',
      label: 'Australian Dollar (AUD)',
      locale: 'en_AU',
      symbol: r'A$',
    ),
  ];

  static AppCurrencyOption optionFor(String? code) {
    final normalized = code?.trim().toUpperCase();
    for (final option in options) {
      if (option.code == normalized) return option;
    }
    return options.firstWhere((option) => option.code == defaultCode);
  }

  static String normalizeCode(String? code) => optionFor(code).code;
}
