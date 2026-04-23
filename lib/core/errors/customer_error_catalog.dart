import 'package:autolab_core/autolab_core.dart';

final class CustomerErrorCatalog {
  CustomerErrorCatalog._();

  static const nameRequired = ErrorItem(
    code: 'CUS_VAL_001',
    message: 'El nombre es obligatorio',
  );

  static const nameTooShort = ErrorItem(
    code: 'CUS_VAL_002',
    message: 'Mínimo 3 caracteres',
  );

  static const emailRequired = ErrorItem(
    code: 'CUS_VAL_003',
    message: 'El correo es obligatorio',
  );

  static const invalidEmail = ErrorItem(
    code: 'CUS_VAL_004',
    message: 'Correo inválido',
  );

  static const phoneRequired = ErrorItem(
    code: 'CUS_VAL_005',
    message: 'El teléfono es obligatorio',
  );

  static const invalidPhone = ErrorItem(
    code: 'CUS_VAL_006',
    message: 'Teléfono inválido',
  );

  static const passwordRequired = ErrorItem(
    code: 'CUS_VAL_007',
    message: 'La contraseña es obligatoria',
  );

  static const passwordTooShort = ErrorItem(
    code: 'CUS_VAL_008',
    message: 'Mínimo 6 caracteres',
  );

  static const confirmPasswordRequired = ErrorItem(
    code: 'CUS_VAL_009',
    message: 'Confirme la contraseña',
  );

  static const passwordsDoNotMatch = ErrorItem(
    code: 'CUS_VAL_010',
    message: 'Las contraseñas no coinciden',
  );

  static const termsRequired = ErrorItem(
    code: 'CUS_VAL_011',
    message: 'Debes aceptar términos y condiciones',
  );

  static const locationPermissionRequired = ErrorItem(
    code: 'CUS_LOC_001',
    message: 'Activa tu ubicación para ver talleres y servicios cercanos.',
  );

  static const locationServiceDisabled = ErrorItem(
    code: 'CUS_LOC_002',
    message: 'Enciende el GPS del dispositivo para continuar.',
  );

  static const invalidCurrentLocation = ErrorItem(
    code: 'CUS_LOC_003',
    message: 'No pudimos obtener una ubicación válida. Intenta nuevamente.',
  );

  static const locationConfigurationIncomplete = ErrorItem(
    code: 'CUS_LOC_004',
    message:
        'La ubicación no está disponible en este momento. Intenta más tarde.',
  );

  static const locationPermissionRestricted = ErrorItem(
    code: 'CUS_LOC_005',
    message: 'La ubicación está restringida por el sistema operativo.',
  );

  static const locationActionFailed = ErrorItem(
    code: 'CUS_LOC_006',
    message:
        'No fue posible completar la acción de ubicación. Intenta nuevamente.',
  );

  static const locationRequestTimeout = ErrorItem(
    code: 'NET_002',
    message: 'La ubicación tardó demasiado en responder. Intenta nuevamente.',
  );

  static const workshopLoadFailed = ErrorItem(
    code: 'CUS_WRK_001',
    message: 'No fue posible cargar los talleres en este momento.',
  );

  static const workshopNetworkError = ErrorItem(
    code: 'CUS_WRK_002',
    message: 'Revisa tu conexión para consultar los talleres cercanos.',
  );
}
