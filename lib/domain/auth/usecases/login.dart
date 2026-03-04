import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;
  Login(this.repository);

  Future<void> call() => repository.login();
}