class LoginAttemptState {
  // Cantidad de intentos fallidos consecutivos
  final int failedAttempts;

  // Nivel de bloqueo (define cuánto tiempo se bloquea)
  final int lockLevel;

  // Fecha/hora hasta la que el usuario está bloqueado
  // Si es null → no está bloqueado
  final DateTime? blockedUntil;

  // Constructor principal
  const LoginAttemptState({
    required this.failedAttempts,
    required this.lockLevel,
    required this.blockedUntil,
  });

  // Estado inicial: sin intentos, sin bloqueo
  factory LoginAttemptState.initial() {
    return const LoginAttemptState(
      failedAttempts: 0,
      lockLevel: 0,
      blockedUntil: null,
    );
  }

  // Indica si el usuario está actualmente bloqueado
  bool get isBlocked {
    if (blockedUntil == null) return false;
    return DateTime.now().isBefore(blockedUntil!);
  }

  // Tiempo restante de bloqueo
  Duration get remainingTime {
    if (blockedUntil == null) return Duration.zero;
    final diff = blockedUntil!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // Permite crear una copia del estado modificando algunos valores
  LoginAttemptState copyWith({
    int? failedAttempts,
    int? lockLevel,
    DateTime? blockedUntil,
  }) {
    return LoginAttemptState(
      // Si viene un nuevo valor lo usa, si no mantiene el actual
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockLevel: lockLevel ?? this.lockLevel,
      blockedUntil: blockedUntil ?? this.blockedUntil,
    );
  }

  // Convierte el objeto a JSON para guardarlo en SharedPreferences
  Map<String, dynamic> toJson() => {
    'failedAttempts': failedAttempts,
    'lockLevel': lockLevel,
    'blockedUntil': blockedUntil?.toIso8601String(),
  };

  // Convierte JSON en objeto (cuando se lee de almacenamiento)
  factory LoginAttemptState.fromJson(Map<String, dynamic> json) {
    return LoginAttemptState(
      failedAttempts: json['failedAttempts'] ?? 0,
      lockLevel: json['lockLevel'] ?? 0,
      blockedUntil: json['blockedUntil'] != null
          ? DateTime.tryParse(json['blockedUntil'])
          : null,
    );
  }
}