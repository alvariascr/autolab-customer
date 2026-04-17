abstract class SessionLocalDataSource {
  Future<void> saveAccessToken(String token);

  Future<void> saveRefreshToken(String token);

  Future<void> saveUserSession(String sessionJson);

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<String?> getUserSession();

  Future<void> clearSession();
}
