import 'package:autolab_core/autolab_core.dart';

final class CustomerErrorCatalog {
  CustomerErrorCatalog._();

  static const nameRequired = ErrorItem(
    code: 'CUS_VAL_001',
    uiKey: 'validationNameRequired',
  );

  static const nameTooShort = ErrorItem(
    code: 'CUS_VAL_002',
    uiKey: 'validationNameTooShort',
  );

  static const emailRequired = ErrorItem(
    code: 'CUS_VAL_003',
    uiKey: 'validationEmailRequired',
  );

  static const invalidEmail = ErrorItem(
    code: 'CUS_VAL_004',
    uiKey: 'validationEmailInvalid',
  );

  static const phoneRequired = ErrorItem(
    code: 'CUS_VAL_005',
    uiKey: 'validationPhoneRequired',
  );

  static const invalidPhone = ErrorItem(
    code: 'CUS_VAL_006',
    uiKey: 'validationPhoneInvalid',
  );

  static const passwordRequired = ErrorItem(
    code: 'CUS_VAL_007',
    uiKey: 'validationPasswordRequired',
  );

  static const passwordTooShort = ErrorItem(
    code: 'CUS_VAL_008',
    uiKey: 'validationPasswordTooShort',
  );

  static const confirmPasswordRequired = ErrorItem(
    code: 'CUS_VAL_009',
    uiKey: 'validationConfirmPasswordRequired',
  );

  static const passwordsDoNotMatch = ErrorItem(
    code: 'CUS_VAL_010',
    uiKey: 'validationPasswordsDoNotMatch',
  );

  static const termsRequired = ErrorItem(
    code: 'CUS_VAL_011',
    uiKey: 'authTermsRequired',
  );

  static const locationPermissionRequired = ErrorItem(
    code: 'CUS_LOC_001',
    uiKey: 'locationErrorPermissionRequired',
  );

  static const locationServiceDisabled = ErrorItem(
    code: 'CUS_LOC_002',
    uiKey: 'locationErrorServiceDisabled',
  );

  static const invalidCurrentLocation = ErrorItem(
    code: 'CUS_LOC_003',
    uiKey: 'locationErrorInvalidCurrentLocation',
  );

  static const locationConfigurationIncomplete = ErrorItem(
    code: 'CUS_LOC_004',
    uiKey: 'locationErrorConfigurationIncomplete',
  );

  static const locationPermissionRestricted = ErrorItem(
    code: 'CUS_LOC_005',
    uiKey: 'locationErrorPermissionRestricted',
  );

  static const locationActionFailed = ErrorItem(
    code: 'CUS_LOC_006',
    uiKey: 'locationErrorActionFailed',
  );

  static const locationRequestTimeout = ErrorItem(
    code: 'NET_002',
    uiKey: 'locationErrorRequestTimeout',
  );

  static const workshopLoadFailed = ErrorItem(
    code: 'CUS_WRK_001',
    uiKey: 'workshopErrorLoadFailed',
  );

  static const workshopNetworkError = ErrorItem(
    code: 'CUS_WRK_002',
    uiKey: 'workshopErrorNetwork',
  );
}
