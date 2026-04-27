import 'package:shared_preferences/shared_preferences.dart';

abstract class LocationFlowRecoveryService {
  Future<void> markPendingSettingsSync();
  Future<bool> consumePendingSettingsSync();
}

class SharedPrefsLocationFlowRecoveryService
    implements LocationFlowRecoveryService {
  SharedPrefsLocationFlowRecoveryService(this._prefs);

  static const _pendingSettingsSyncKey = 'location_pending_settings_sync';
  final SharedPreferences _prefs;

  @override
  Future<void> markPendingSettingsSync() async {
    await _prefs.setBool(_pendingSettingsSyncKey, true);
  }

  @override
  Future<bool> consumePendingSettingsSync() async {
    final pending = _prefs.getBool(_pendingSettingsSyncKey) ?? false;

    if (pending) {
      await _prefs.remove(_pendingSettingsSyncKey);
    }

    return pending;
  }
}
