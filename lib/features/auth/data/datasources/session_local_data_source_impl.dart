import 'package:autolab_core/autolab_core.dart';

import 'secure_storage_keys.dart';
import 'session_local_data_source.dart';

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl(this.secureStorage);

  final SecureStorage secureStorage;

  @override
  Future<void> saveAccessToken(String token) async {
    await secureStorage.write(key: SecureStorageKeys.accessToken, value: token);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await secureStorage.write(
      key: SecureStorageKeys.refreshToken,
      value: token,
    );
  }

  @override
  Future<void> saveUserSession(String sessionJson) async {
    await secureStorage.write(
      key: SecureStorageKeys.userSession,
      value: sessionJson,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    return secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  @override
  Future<String?> getUserSession() async {
    return secureStorage.read(key: SecureStorageKeys.userSession);
  }

  @override
  Future<void> clearSession() async {
    await secureStorage.delete(key: SecureStorageKeys.accessToken);
    await secureStorage.delete(key: SecureStorageKeys.refreshToken);
    await secureStorage.delete(key: SecureStorageKeys.userSession);
  }
}
