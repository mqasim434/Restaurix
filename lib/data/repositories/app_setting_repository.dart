import 'package:isar/isar.dart';

import '../../core/settings/app_setting_keys.dart';
import '../../domain/models/app_settings.dart';
import '../local/collections/app_setting_isar.dart';

class AppSettingRepository {
  AppSettingRepository(this._isar);

  final Isar _isar;

  Stream<AppSettings> watchSettings() {
    return _isar.appSettingIsars.watchLazy(fireImmediately: true).asyncMap(
          (_) => loadSettings(),
        );
  }

  Future<AppSettings> loadSettings() async {
    final records = await _isar.appSettingIsars.where().findAll();
    final values = {for (final record in records) record.key: record.value};
    return _settingsFromMap(values);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _isar.writeTxn(() async {
      await _writeKey(AppSettingKeys.businessName, settings.businessName);
      await _writeKey(AppSettingKeys.businessAddress, settings.businessAddress);
      await _writeKey(AppSettingKeys.receiptHeaderText, settings.receiptHeaderText);
      await _writeKey(AppSettingKeys.receiptFooterText, settings.receiptFooterText);
      await _writeKey(
        AppSettingKeys.receiptPrinterId,
        settings.receiptPrinterTarget,
      );
      await _writeKey(
        AppSettingKeys.kitchenDefaultPrinterId,
        settings.kitchenDefaultPrinterTarget,
      );
      await _writeKey(
        AppSettingKeys.printerConfigs,
        encodePrinterConfigs(settings.printers),
      );
      await _writeKey(
        AppSettingKeys.kitchenCategoryPrinterMap,
        encodeCategoryPrinterMap(settings.kitchenCategoryPrinters),
      );
      await _writeKey(
        AppSettingKeys.salaryGenerationDay,
        settings.salaryGenerationDay.toString(),
      );
    });
  }

  Future<String?> getString(String key) async {
    final record =
        await _isar.appSettingIsars.filter().keyEqualTo(key).findFirst();
    return record?.value;
  }

  Future<String?> getKitchenDefaultPrinterId() async {
    final settings = await loadSettings();
    return settings.kitchenDefaultPrinterTarget;
  }

  Future<String?> getReceiptPrinterId() async {
    final settings = await loadSettings();
    return settings.receiptPrinterTarget;
  }

  Future<String> getBusinessName() async {
    final settings = await loadSettings();
    final name = settings.businessName.trim();
    if (name.isEmpty) return AppSettings.defaults.businessName;
    return name;
  }

  Future<void> setString(String key, String? value) async {
    await _isar.writeTxn(() async {
      await _writeKey(key, value);
    });
  }

  Future<void> _writeKey(String key, String? value) async {
    final existing =
        await _isar.appSettingIsars.filter().keyEqualTo(key).findFirst();

    if (value == null || value.trim().isEmpty) {
      if (existing != null) {
        await _isar.appSettingIsars.delete(existing.id);
      }
      return;
    }

    final record = existing ?? (AppSettingIsar()..key = key);
    record.value = value.trim();
    await _isar.appSettingIsars.put(record);
  }

  AppSettings _settingsFromMap(Map<String, String?> values) {
    final businessName = values[AppSettingKeys.businessName]?.trim();
    return AppSettings(
      businessName: businessName == null || businessName.isEmpty
          ? AppSettings.defaults.businessName
          : businessName,
      businessAddress: values[AppSettingKeys.businessAddress],
      receiptHeaderText: values[AppSettingKeys.receiptHeaderText],
      receiptFooterText: values[AppSettingKeys.receiptFooterText],
      receiptPrinterTarget: values[AppSettingKeys.receiptPrinterId],
      kitchenDefaultPrinterTarget: values[AppSettingKeys.kitchenDefaultPrinterId],
      printers: decodePrinterConfigs(values[AppSettingKeys.printerConfigs]),
      kitchenCategoryPrinters:
          decodeCategoryPrinterMap(values[AppSettingKeys.kitchenCategoryPrinterMap]),
      salaryGenerationDay:
          parseSalaryGenerationDay(values[AppSettingKeys.salaryGenerationDay]),
    );
  }
}
