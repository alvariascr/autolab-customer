import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/user_role_data_source.dart';
import 'auth_session_storage_service.dart';

class AuthSupabaseSessionSyncService {
  AuthSupabaseSessionSyncService({
    required AuthSessionStorageService sessionStorageService,
    required UserRoleDataSource userRoleDataSource,
    required FeatureLogger featureLogger,
  }) : _sessionStorageService = sessionStorageService,
       _userRoleDataSource = userRoleDataSource,
       _featureLogger = featureLogger;

  final AuthSessionStorageService _sessionStorageService;
  final UserRoleDataSource _userRoleDataSource;
  final FeatureLogger _featureLogger;

  Future<Either<Failure, AppUser>> syncUser(User supabaseUser) async {
    try {
      final role = await _userRoleDataSource.getUserRole(supabaseUser.id);
      await _sessionStorageService.saveUserSession(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );

      _featureLogger.info(
        feature: 'auth',
        action: 'restore_from_supabase_user_succeeded',
        context: {'userId': supabaseUser.id, 'role': role},
      );

      return Right(
        AppUser(id: supabaseUser.id, email: supabaseUser.email, role: role),
      );
    } catch (error, stackTrace) {
      final failure = AuthFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );

      _featureLogger.error(
        feature: 'auth',
        action: 'restore_from_supabase_user_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'userId': supabaseUser.id},
        error: error,
        stackTrace: stackTrace,
      );

      return Left(failure);
    }
  }
}
