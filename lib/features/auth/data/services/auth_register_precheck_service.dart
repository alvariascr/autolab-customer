import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/mappers/auth_exception_mapper.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRegisterPrecheckService {
  AuthRegisterPrecheckService({
    required SupabaseClient client,
    required AuthExceptionMapper authExceptionMapper,
    required GlobalErrorHandler globalErrorHandler,
    required FeatureLogger featureLogger,
  }) : _client = client,
       _authExceptionMapper = authExceptionMapper,
       _globalErrorHandler = globalErrorHandler,
       _featureLogger = featureLogger;

  final SupabaseClient _client;
  final AuthExceptionMapper _authExceptionMapper;
  final GlobalErrorHandler _globalErrorHandler;
  final FeatureLogger _featureLogger;

  Future<Failure?> precheck({
    required String cleanEmail,
    required String cleanPassword,
  }) async {
    try {
      final loginResponse = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (loginResponse.user == null) {
        return null;
      }

      await _client.auth.signOut();
      _featureLogger.warn(
        feature: 'auth',
        action: 'register_precheck_account_exists',
        code: AuthErrorCatalog.accountAlreadyExists.code,
        context: {
          'email': cleanEmail,
          'uiKey': AuthErrorCatalog.accountAlreadyExists.uiKey,
        },
      );
      return AuthFailure.fromErrorItem(AuthErrorCatalog.accountAlreadyExists);
    } on AuthException catch (error, stackTrace) {
      final mapping = _authExceptionMapper.map(
        error,
        stackTrace,
        flow: AuthExceptionFlow.registerPrecheck,
      );

      if (_authExceptionMapper.isRegisterAvailabilitySignal(error)) {
        _featureLogger.info(
          feature: 'auth',
          action: 'register_precheck_available',
          context: _authExceptionMapper.buildLogContext(
            error,
            flow: AuthExceptionFlow.registerPrecheck,
            email: cleanEmail,
            classification: 'register_available',
          ),
        );
        return null;
      }

      if (mapping != null) {
        _featureLogger.warn(
          feature: 'auth',
          action: 'register_precheck_auth_exception_mapped',
          code: mapping.failure.code,
          context: _authExceptionMapper.buildLogContext(
            error,
            flow: AuthExceptionFlow.registerPrecheck,
            email: cleanEmail,
            failure: mapping.failure,
            classification: mapping.classification,
          ),
          error: error,
          stackTrace: stackTrace,
        );
        return mapping.failure;
      }

      _featureLogger.error(
        feature: 'auth',
        action: 'register_precheck_unhandled_auth_exception',
        context: _authExceptionMapper.buildLogContext(
          error,
          flow: AuthExceptionFlow.registerPrecheck,
          email: cleanEmail,
          resolution: 'delegated_to_global_error_handler',
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return _globalErrorHandler.handle(error, stackTrace);
    }
  }
}
