import 'package:isar/isar.dart';

import '../../core/constants.dart';
import '../../core/settings/app_setting_keys.dart';
import '../local/collections/app_setting_isar.dart';

class AppSettingRepository {
  AppSettingRepository(this._isar);

  final Isar _isar;

  Future<String?> getString(String key) async {
    final record =
        await _isar.appSettingIsars.filter().keyEqualTo(key).findFirst();
    return record?.value;
  }

  Future<String?> getKitchenDefaultPrinterId() {
    return getString(AppSettingKeys.kitchenDefaultPrinterId);
  }

  Future<String?> getReceiptPrinterId() {
    return getString(AppSettingKeys.receiptPrinterId);
  }

  Future<String> getBusinessName() async {
    final value = await getString(AppSettingKeys.businessName);
    if (value == null || value.trim().isEmpty) {
      return AppConstants.defaultBusinessName;
    }
    return value.trim();
  }

  Future<void> setString(String key, String? value) async {
    await _isar.writeTxn(() async {
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
    });
  }
}
