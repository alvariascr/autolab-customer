import '../../l10n/app_localizations.dart';

class Validators {
  static String? name(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationNameRequired;
    }
    if (value.trim().length < 3) {
      return l10n.validationNameTooShort;
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.validationEmailInvalid;
    }

    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationPhoneRequired;
    }
    if (value.trim().length < 8) {
      return l10n.validationPhoneInvalid;
    }
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordRequired;
    }
    if (value.length < 6) {
      return l10n.validationPasswordTooShort;
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String originalPassword,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.validationConfirmPasswordRequired;
    }
    if (value != originalPassword) {
      return l10n.validationPasswordsDoNotMatch;
    }
    return null;
  }
}
