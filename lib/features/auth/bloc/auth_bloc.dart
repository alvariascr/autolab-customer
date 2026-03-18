import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(const AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<RegisterRequested>(_onRegister);
    on<RestoreSession>(_onRestoreSession);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await repository.login(event.email, event.password);

    result.fold(
      (Failure failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(userId: user.id, role: user.role)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await repository.logout();

    result.fold(
      (Failure failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthInitial()),
    );
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await repository.register(event.email, event.password);

    result.fold(
      (Failure failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(userId: user.id, role: user.role)),
    );
  }

  Future<void> _onRestoreSession(
    RestoreSession event,
    Emitter<AuthState> emit,
  ) async {
    final user = await repository.getCurrentUser();

    if (user != null) {
      emit(AuthSuccess(userId: user.id, role: user.role));
    } else {
      emit(const AuthInitial());
    }
  }
}
