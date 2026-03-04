import '../repositories/auth_repository.dart';

class GetAuthStatus {
  final AuthRepository repository;
  GetAuthStatus(this.repository);

  bool call() => repository.isAuthenticated();
}