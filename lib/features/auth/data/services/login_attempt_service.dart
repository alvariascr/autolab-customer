import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_attempt_state.dart';

class LoginAttemptService {
  LoginAttemptService(this._prefs);

  static const _prefix = 'login_attempt_';
  final SharedPreferences _prefs;

  // Genera una llave única por correo
  String _key(String email) => '$_prefix${email.trim().toLowerCase()}';

  // Obtiene el estado actual del usuario
  Future<LoginAttemptState> getState(String email) async {
    final raw = _prefs.getString(_key(email));
    if (raw == null) return LoginAttemptState.initial();
    final state = LoginAttemptState.fromJson(jsonDecode(raw));
    if (state.blockedUntil != null &&
        DateTime.now().isAfter(state.blockedUntil!)) {
      final reset = LoginAttemptState(
        failedAttempts: 0,
        lockLevel: state.lockLevel,
        blockedUntil: null,
      );
      await saveState(email, reset);
      return reset;
    }
    return state;
  }

  // Guarda el estado en almacenamiento local
  Future<void> saveState(String email, LoginAttemptState state) async {
    await _prefs.setString(_key(email), jsonEncode(state.toJson()));
  }

  // Se llama cuando el login es exitoso
  Future<void> registerSuccess(String email) async {
    await saveState(email, LoginAttemptState.initial());
  }

  // Se llama cuando el login falla
  Future<LoginAttemptState> registerFailure(String email) async {
    final current = await getState(email);
    final nextAttempts = current.failedAttempts + 1;
    if (nextAttempts < 5) {
      final updated = LoginAttemptState(
        failedAttempts: nextAttempts,
        lockLevel: current.lockLevel,
        blockedUntil: current.blockedUntil,
      );

      await saveState(email, updated);
      return updated;
    }
    final nextLevel = current.lockLevel + 1;
    final duration = _getDuration(nextLevel);
    final blocked = LoginAttemptState(
      failedAttempts: 0,
      lockLevel: nextLevel,
      blockedUntil: DateTime.now().add(duration),
    );
    await saveState(email, blocked);
    return blocked;
  }

  // Define cuánto dura el bloqueo según el nivel
  Duration _getDuration(int level) {
    switch (level) {
      case 1:
        return const Duration(minutes: 1);
      case 2:
        return const Duration(minutes: 5);
      case 3:
        return const Duration(minutes: 15);
      default:
        return const Duration(minutes: 30);
    }
  }
}
