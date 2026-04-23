import 'package:equatable/equatable.dart';

import '../domain/entities/app_user.dart';

enum LoginFormStatus { initial, submitting, success, error }

class LoginFormState extends Equatable {
  const LoginFormState({
    required this.status,
    this.user,
    this.message,
    this.code,
    this.remaining,
  });

  const LoginFormState.initial() : this(status: LoginFormStatus.initial);

  final LoginFormStatus status;
  final AppUser? user;
  final String? message;
  final String? code;
  final Duration? remaining;

  LoginFormState copyWith({
    LoginFormStatus? status,
    AppUser? user,
    String? message,
    String? code,
    Duration? remaining,
    bool clearUser = false,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearRemaining = false,
  }) {
    return LoginFormState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      message: clearMessage ? null : (message ?? this.message),
      code: clearCode ? null : (code ?? this.code),
      remaining: clearRemaining ? null : (remaining ?? this.remaining),
    );
  }

  @override
  List<Object?> get props => [status, user, message, code, remaining];
}
