import 'package:equatable/equatable.dart';

enum PasswordRecoveryStatus { initial, submitting, success, error }

class PasswordRecoveryState extends Equatable {
  const PasswordRecoveryState({
    required this.status,
    this.message,
    this.code,
    this.uiKey,
  });

  const PasswordRecoveryState.initial()
    : this(status: PasswordRecoveryStatus.initial);

  final PasswordRecoveryStatus status;
  final String? message;
  final String? code;
  final String? uiKey;

  PasswordRecoveryState copyWith({
    PasswordRecoveryStatus? status,
    String? message,
    String? code,
    String? uiKey,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearUiKey = false,
  }) {
    return PasswordRecoveryState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      code: clearCode ? null : (code ?? this.code),
      uiKey: clearUiKey ? null : (uiKey ?? this.uiKey),
    );
  }

  @override
  List<Object?> get props => [status, message, code, uiKey];
}
