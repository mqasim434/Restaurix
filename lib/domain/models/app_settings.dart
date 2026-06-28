import 'dart:convert';

import '../../core/constants.dart';

class PrinterConfig {
  const PrinterConfig({
    required this.id,
    required this.name,
    required this.target,
  });

  final String id;
  final String name;
  final String target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      target: json['target'] as String,
    );
  }

  PrinterConfig copyWith({
    String? name,
    String? target,
  }) {
    return PrinterConfig(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.businessName,
    this.businessAddress,
    this.receiptHeaderText,
    this.receiptFooterText,
    this.receiptPrinterTarget,
    this.kitchenDefaultPrinterTarget,
    this.printers = const [],
    this.kitchenCategoryPrinters = const {},
    this.salaryGenerationDay = 1,
  });

  final String businessName;
  final String? businessAddress;
  final String? receiptHeaderText;
  final String? receiptFooterText;
  final String? receiptPrinterTarget;
  final String? kitchenDefaultPrinterTarget;
  final List<PrinterConfig> printers;
  final Map<String, String> kitchenCategoryPrinters;
  final int salaryGenerationDay;

  static const defaults = AppSettings(
    businessName: AppConstants.defaultBusinessName,
    salaryGenerationDay: 1,
  );

  String? resolvePrinterTarget(String? reference) {
    final trimmed = reference?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    for (final printer in printers) {
      if (printer.id == trimmed) return printer.target.trim();
    }

    return trimmed;
  }

  String? resolvedReceiptPrinterTarget() =>
      resolvePrinterTarget(receiptPrinterTarget);

  String? resolvedKitchenDefaultPrinterTarget() =>
      resolvePrinterTarget(kitchenDefaultPrinterTarget);

  String? resolveKitchenCategoryPrinter(String? kitchenCategory) {
    final category = kitchenCategory?.trim();
    if (category == null || category.isEmpty) return null;
    return resolvePrinterTarget(kitchenCategoryPrinters[category]);
  }

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    bool clearBusinessAddress = false,
    String? receiptHeaderText,
    bool clearReceiptHeaderText = false,
    String? receiptFooterText,
    bool clearReceiptFooterText = false,
    String? receiptPrinterTarget,
    bool clearReceiptPrinterTarget = false,
    String? kitchenDefaultPrinterTarget,
    bool clearKitchenDefaultPrinterTarget = false,
    List<PrinterConfig>? printers,
    Map<String, String>? kitchenCategoryPrinters,
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
      receiptPrinterTarget: clearReceiptPrinterTarget
          ? null
          : (receiptPrinterTarget ?? this.receiptPrinterTarget),
      kitchenDefaultPrinterTarget: clearKitchenDefaultPrinterTarget
          ? null
          : (kitchenDefaultPrinterTarget ?? this.kitchenDefaultPrinterTarget),
      printers: printers ?? this.printers,
      kitchenCategoryPrinters:
          kitchenCategoryPrinters ?? this.kitchenCategoryPrinters,
      salaryGenerationDay: salaryGenerationDay ?? this.salaryGenerationDay,
    );
  }
}

List<PrinterConfig> decodePrinterConfigs(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return [
    for (final entry in decoded)
      if (entry is Map<String, dynamic>) PrinterConfig.fromJson(entry),
  ];
}

String encodePrinterConfigs(List<PrinterConfig> printers) {
  return jsonEncode(printers.map((printer) => printer.toJson()).toList());
}

Map<String, String> decodeCategoryPrinterMap(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return const {};
  return decoded.map(
    (key, value) => MapEntry(key.toString(), value.toString()),
  );
}

String encodeCategoryPrinterMap(Map<String, String> map) {
  return jsonEncode(map);
}

int parseSalaryGenerationDay(String? raw) {
  final parsed = int.tryParse(raw ?? '');
  if (parsed == null) return AppSettings.defaults.salaryGenerationDay;
  return parsed.clamp(1, 28);
}
