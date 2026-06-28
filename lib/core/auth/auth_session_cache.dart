import '../../data/repositories/app_setting_repository.dart';
import '../../domain/models/app_user.dart';
import '../settings/app_setting_keys.dart';

/// Persists the signed-in profile locally for offline use after login.
class AuthSessionCache {
  AuthSessionCache(this._settings);

  final AppSettingRepository _settings;

  Future<AppUser?> load() async {
    final raw = await _settings.getString(AppSettingKeys.authCachedSession);
    return AppUser.decodeCached(raw);
  }

  Future<void> save(AppUser user) async {
    await _settings.setString(
      AppSettingKeys.authCachedSession,
      user.encodeCached(),
    );
  }

  Future<void> clear() async {
    await _settings.setString(AppSettingKeys.authCachedSession, null);
  }
}
