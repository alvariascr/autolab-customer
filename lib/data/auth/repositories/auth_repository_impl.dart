import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource local;

  AuthRepositoryImpl(this.local);

  @override
  bool isAuthenticated() => local.isAuthenticated();

  @override
  Future<void> login() => local.login();

  @override
  Future<void> logout() => local.logout();
}