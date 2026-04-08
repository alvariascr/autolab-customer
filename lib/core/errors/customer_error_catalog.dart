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
}
