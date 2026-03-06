/*
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain.auth/usecases/get_auth_status.dart';
import '../domain.auth/usecases/login.dart';
import '../domain.auth/usecases/logout.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final GetAuthStatus _getAuthStatus;
  final Login _login;
  final Logout _logout;

  AuthenticationCubit({
    required GetAuthStatus getAuthStatus,
    required Login login,
    required Logout logout,
  })  : _getAuthStatus = getAuthStatus,
        _login = login,
        _logout = logout,
        super(const AuthenticationState.unauthenticated()) {
    refresh();
  }

  bool get isLoggedIn => _getAuthStatus();

  void refresh() {
    emit(
      isLoggedIn
          ? const AuthenticationState.authenticated()
          : const AuthenticationState.unauthenticated(),
    );
  }

  Future<void> signIn() async {
    await _login();
    refresh();
  }

  Future<void> signOut() async {
    await _logout();
    refresh();
  }
}*/
