import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/isar_service.dart';
import '../../../data/repositories/app_setting_repository.dart';
import '../../../domain/models/app_settings.dart';

final appSettingRepositoryProvider = Provider<AppSettingRepository>((ref) {
  return AppSettingRepository(ref.watch(isarProvider));
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(appSettingRepositoryProvider).watchSettings();
});

final settingsActionsProvider = Provider<SettingsActions>((ref) {
  return SettingsActions(ref);
});

class SettingsActions {
  SettingsActions(this._ref);

  final Ref _ref;

  Future<void> save(AppSettings settings) {
    return _ref.read(appSettingRepositoryProvider).saveSettings(settings);
  }
}
