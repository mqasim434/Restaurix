import 'package:isar/isar.dart';

part 'app_setting_isar.g.dart';

/// Local key-value settings persisted in Isar.
@collection
class AppSettingIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? value;
}
