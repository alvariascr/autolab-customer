import 'package:autolab_core/autolab_core.dart';

final class AuthErrorCatalog {
  AuthErrorCatalog._();

  static const invalidCredentials = ErrorItem(
    code: 'AUTH_001',
    uiKey: 'authErrorInvalidCredentials',
  );

  static const sessionExpired = ErrorItem(
    code: 'AUTH_002',
    uiKey: 'authErrorSessionExpired',
  );

  static const unauthorized = ErrorItem(
    code: 'AUTH_003',
    uiKey: 'authErrorUnauthorized',
  );

  static const invalidAuthResponse = ErrorItem(
    code: 'AUTH_004',
    uiKey: 'authErrorInvalidAuthResponse',
  );

  static const userProfileNotFound = ErrorItem(
    code: 'AUTH_005',
    uiKey: 'authErrorUserProfileNotFound',
  );

  static const undefinedUserRole = ErrorItem(
    code: 'AUTH_006',
    uiKey: 'authErrorUndefinedUserRole',
  );

  static const unconfirmedEmail = ErrorItem(
    code: 'AUTH_007',
    uiKey: 'authErrorUnconfirmedEmail',
  );

  static const emailAlreadyRegistered = ErrorItem(
    code: 'AUTH_008',
    uiKey: 'authErrorEmailAlreadyRegistered',
  );

  static const invalidRegisterResponse = ErrorItem(
    code: 'AUTH_009',
    uiKey: 'authErrorInvalidRegisterResponse',
  );

  static const authRateLimit = ErrorItem(
    code: 'AUTH_010',
    uiKey: 'authErrorRateLimit',
  );

  static const sessionRestoreFailed = ErrorItem(
    code: 'AUTH_011',
    uiKey: 'authErrorSessionRestoreFailed',
  );

  static const localSessionRecoveryFailed = ErrorItem(
    code: 'AUTH_012',
    uiKey: 'authErrorLocalSessionRecoveryFailed',
  );

  static const invalidEmail = ErrorItem(
    code: 'REG_001',
    uiKey: 'authErrorInvalidEmail',
  );

  static const weakPassword = ErrorItem(
    code: 'REG_002',
    uiKey: 'authErrorWeakPassword',
  );

  static const emailNotConfirmedRegister = ErrorItem(
    code: 'REG_003',
    uiKey: 'authErrorEmailNotConfirmedRegister',
  );

  static const accountAlreadyExists = ErrorItem(
    code: 'REG_004',
    uiKey: 'authErrorAccountAlreadyExists',
  );

  static const registerRateLimit = ErrorItem(
    code: 'REG_005',
    uiKey: 'authErrorRegisterRateLimit',
  );

  static const registerUnexpectedError = ErrorItem(
    code: 'REG_006',
    uiKey: 'authErrorRegisterUnexpected',
  );
}
