abstract class AuthRepository {
  bool isAuthenticated();
  Future<void> login();
  Future<void> logout();
}