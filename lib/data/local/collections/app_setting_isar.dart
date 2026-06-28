import 'package:isar/isar.dart';

part 'app_setting_isar.g.dart';

/// Simple local key-value settings until Module 29 (Settings screen).
@collection
class AppSettingIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? value;
}
