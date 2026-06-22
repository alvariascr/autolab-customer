import 'package:equatable/equatable.dart';

enum AuthSessionStatus { initial, loading, authenticated, unauthenticated }

class AuthSessionState extends Equatable {
  const AuthSessionState({
    required this.status,
    this.userId,
    this.role,
    this.showCustomerOnboarding = false,
    this.message,
    this.code,
    this.uiKey,
  });

  const AuthSessionState.initial() : this(status: AuthSessionStatus.initial);

  final AuthSessionStatus status;
  final String? userId;
  final String? role;
  final bool showCustomerOnboarding;
  final String? message;
  final String? code;
  final String? uiKey;

  bool get isAuthenticated => status == AuthSessionStatus.authenticated;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    String? userId,
    String? role,
    bool? showCustomerOnboarding,
    String? message,
    String? code,
    String? uiKey,
    bool clearUser = false,
    bool clearMessage = false,
    bool clearCode = false,
    bool clearUiKey = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      userId: clearUser ? null : (userId ?? this.userId),
      role: clearUser ? null : (role ?? this.role),
      showCustomerOnboarding:
          showCustomerOnboarding ?? this.showCustomerOnboarding,
      message: clearMessage ? null : (message ?? this.message),
      code: clearCode ? null : (code ?? this.code),
      uiKey: clearUiKey ? null : (uiKey ?? this.uiKey),
    );
  }

  @override
  List<Object?> get props => [
    status,
    userId,
    role,
    showCustomerOnboarding,
    message,
    code,
    uiKey,
  ];
}
