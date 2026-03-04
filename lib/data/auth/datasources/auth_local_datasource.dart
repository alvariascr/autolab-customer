class AuthLocalDataSource {
  bool _loggedIn = false;

  bool isAuthenticated() => _loggedIn;

  Future<void> login() async {
    _loggedIn = true;
  }

  Future<void> logout() async {
    _loggedIn = false;
  }
}