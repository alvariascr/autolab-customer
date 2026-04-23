import 'package:equatable/equatable.dart';

enum AuthSessionStatus { initial, loading, authenticated, unauthenticated }

class AuthSessionState extends Equatable {
  const AuthSessionState({
    required this.status,
    this.userId,
    this.role,
    this.message,
  });

  const AuthSessionState.initial() : this(status: AuthSessionStatus.initial);

  final AuthSessionStatus status;
  final String? userId;
  final String? role;
  final String? message;

  bool get isAuthenticated => status == AuthSessionStatus.authenticated;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    String? userId,
    String? role,
    String? message,
    bool clearUser = false,
    bool clearMessage = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      userId: clearUser ? null : (userId ?? this.userId),
      role: clearUser ? null : (role ?? this.role),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, userId, role, message];
}
