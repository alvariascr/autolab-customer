import 'package:autolab_core/autolab_core.dart';

final class AuthErrorCatalog {
  AuthErrorCatalog._();

  static const invalidCredentials = ErrorItem(
    code: 'AUTH_001',
    message: 'Correo o contraseña incorrectos.',
  );

  static const sessionExpired = ErrorItem(
    code: 'AUTH_002',
    message: 'La sesión ha expirado. Inicia sesión nuevamente.',
  );

  static const unauthorized = ErrorItem(
    code: 'AUTH_003',
    message: 'Rol no autorizado.',
  );

  static const invalidAuthResponse = ErrorItem(
    code: 'AUTH_004',
    message: 'Respuesta inválida: usuario o sesión no disponible.',
  );

  static const userProfileNotFound = ErrorItem(
    code: 'AUTH_005',
    message: 'Perfil de usuario no encontrado.',
  );

  static const undefinedUserRole = ErrorItem(
    code: 'AUTH_006',
    message: 'Rol no definido para el usuario.',
  );

  static const unconfirmedEmail = ErrorItem(
    code: 'AUTH_007',
    message: 'Debes confirmar tu correo antes de iniciar sesión.',
  );

  static const emailAlreadyRegistered = ErrorItem(
    code: 'AUTH_008',
    message: 'Este correo ya se encuentra registrado.',
  );

  static const invalidRegisterResponse = ErrorItem(
    code: 'AUTH_009',
    message: 'Respuesta inválida: usuario no disponible.',
  );

  static const authRateLimit = ErrorItem(
    code: 'AUTH_010',
    message: 'Has excedido el número de intentos permitidos.',
  );

  static const sessionRestoreFailed = ErrorItem(
    code: 'AUTH_011',
    message: 'No fue posible restaurar la sesión del usuario.',
  );

  static const localSessionRecoveryFailed = ErrorItem(
    code: 'AUTH_012',
    message: 'No se pudo reconstruir la sesión desde almacenamiento local.',
  );

  static const invalidEmail = ErrorItem(
    code: 'REG_001',
    message: 'El correo ingresado no es válido.',
  );

  static const weakPassword = ErrorItem(
    code: 'REG_002',
    message: 'La contraseña no cumple los requisitos.',
  );

  static const emailNotConfirmedRegister = ErrorItem(
    code: 'REG_003',
    message: 'Esta cuenta ya existe, pero debes confirmar tu correo.',
  );

  static const accountAlreadyExists = ErrorItem(
    code: 'REG_004',
    message: 'Esta cuenta ya existe. Inicia sesión.',
  );

  static const registerRateLimit = ErrorItem(
    code: 'REG_005',
    message:
        'Se alcanzó el límite de intentos de registro. Intenta nuevamente en unos minutos.',
  );

  static const registerUnexpectedError = ErrorItem(
    code: 'REG_006',
    message: 'No se pudo completar el registro. Intenta nuevamente.',
  );
}
