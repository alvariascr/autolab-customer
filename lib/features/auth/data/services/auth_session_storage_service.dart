import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../datasources/session_local_data_source.dart';

class AuthSessionStorageService {
  AuthSessionStorageService(this._sessionLocalDataSource);

  final SessionLocalDataSource _sessionLocalDataSource;

  Future<void> persistSessionTokens(Session session) async {
    await _sessionLocalDataSource.saveAccessToken(session.accessToken);

    final refreshToken = session.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _sessionLocalDataSource.saveRefreshToken(refreshToken);
    }
  }

  Future<void> saveUserSession({
    required String id,
    required String? email,
    required String role,
  }) {
    final sessionJson = jsonEncode({'id': id, 'email': email, 'role': role});
    return _sessionLocalDataSource.saveUserSession(sessionJson);
  }

  Future<String?> getRefreshToken() {
    return _sessionLocalDataSource.getRefreshToken();
  }

  Future<String?> getUserSession() {
    return _sessionLocalDataSource.getUserSession();
  }

  Future<void> clearSession() {
    return _sessionLocalDataSource.clearSession();
  }

  AppUser? parseStoredUserSession(String sessionJson) {
    final map = jsonDecode(sessionJson) as Map<String, dynamic>;
    final role = map['role'] as String?;

    if (role == null) {
      return null;
    }

    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String?,
      role: role,
    );
  }
}
