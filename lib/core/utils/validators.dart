import '../errors/customer_error_catalog.dart';

class Validators {
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CustomerErrorCatalog.nameRequired.message;
    }
    if (value.trim().length < 3) {
      return CustomerErrorCatalog.nameTooShort.message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CustomerErrorCatalog.emailRequired.message;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return CustomerErrorCatalog.invalidEmail.message;
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CustomerErrorCatalog.phoneRequired.message;
    }
    if (value.trim().length < 8) {
      return CustomerErrorCatalog.invalidPhone.message;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return CustomerErrorCatalog.passwordRequired.message;
    }
    if (value.length < 6) {
      return CustomerErrorCatalog.passwordTooShort.message;
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return CustomerErrorCatalog.confirmPasswordRequired.message;
    }
    if (value != originalPassword) {
      return CustomerErrorCatalog.passwordsDoNotMatch.message;
    }
    return null;
  }
}
