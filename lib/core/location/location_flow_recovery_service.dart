import 'package:shared_preferences/shared_preferences.dart';

abstract class LocationFlowRecoveryService {
  Future<void> markPendingSettingsSync();
  Future<bool> consumePendingSettingsSync();
}

class SharedPrefsLocationFlowRecoveryService
    implements LocationFlowRecoveryService {
  static const _pendingSettingsSyncKey = 'location_pending_settings_sync';

  @override
  Future<void> markPendingSettingsSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSettingsSyncKey, true);
  }

  @override
  Future<bool> consumePendingSettingsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingSettingsSyncKey) ?? false;

    if (pending) {
      await prefs.remove(_pendingSettingsSyncKey);
    }

    return pending;
  }
}
