import 'package:equatable/equatable.dart';

enum RegisterFormStatus { initial, submitting, success, error }

class RegisterFormState extends Equatable {
  const RegisterFormState({
    required this.status,
    this.userId,
    this.message,
    this.code,
    this.remaining,
  });

  const RegisterFormState.initial() : this(status: RegisterFormStatus.initial);

  final RegisterFormStatus status;
  final String? userId;
  final String? message;
  final String? code;
  final Duration? remaining;

  RegisterFormState copyWith({
    RegisterFormStatus? status,
    String? userId,
    String? message,
    String? code,
    Duration? remaining,
    bool clearUserId = false,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearRemaining = false,
  }) {
    return RegisterFormState(
      status: status ?? this.status,
      userId: clearUserId ? null : (userId ?? this.userId),
      message: clearMessage ? null : (message ?? this.message),
      code: clearCode ? null : (code ?? this.code),
      remaining: clearRemaining ? null : (remaining ?? this.remaining),
    );
  }

  @override
  List<Object?> get props => [status, userId, message, code, remaining];
}
