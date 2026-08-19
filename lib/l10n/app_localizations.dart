import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Autolab Customer'**
  String get appTitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tus datos para iniciar sesión.'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authLoginEmailLabel;

  /// No description provided for @authLoginEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo electrónico'**
  String get authLoginEmailHint;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get authLoginPasswordHint;

  /// No description provided for @authLoginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginSubmit;

  /// No description provided for @authLoginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi contraseña'**
  String get authLoginForgotPassword;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el correo de tu cuenta y te enviaremos un enlace para crear una nueva contraseña.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get authForgotPasswordSubmit;

  /// No description provided for @authPasswordResetEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace de recuperación. Revisa tu correo.'**
  String get authPasswordResetEmailSent;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una nueva contraseña para volver a entrar a tu cuenta.'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetPasswordNewPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get authResetPasswordNewPasswordLabel;

  /// No description provided for @authResetPasswordNewPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nueva contraseña'**
  String get authResetPasswordNewPasswordHint;

  /// No description provided for @authResetPasswordSubmit.
  ///
  /// In es, this message translates to:
  /// **'Actualizar contraseña'**
  String get authResetPasswordSubmit;

  /// No description provided for @authPasswordResetSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña fue actualizada. Inicia sesión nuevamente.'**
  String get authPasswordResetSuccess;

  /// No description provided for @authPasswordResetBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get authPasswordResetBackToLogin;

  /// No description provided for @authLoginSocialPrompt.
  ///
  /// In es, this message translates to:
  /// **'O iniciar sesión con:'**
  String get authLoginSocialPrompt;

  /// No description provided for @authLoginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get authLoginGoogle;

  /// No description provided for @authLoginFacebook.
  ///
  /// In es, this message translates to:
  /// **'Facebook'**
  String get authLoginFacebook;

  /// No description provided for @authLoginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authLoginNoAccount;

  /// No description provided for @authLoginRegisterAction.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get authLoginRegisterAction;

  /// No description provided for @authRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tus datos para registrarse'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get authRegisterNameLabel;

  /// No description provided for @authRegisterNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get authRegisterNameHint;

  /// No description provided for @authRegisterEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authRegisterEmailLabel;

  /// No description provided for @authRegisterEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo electrónico'**
  String get authRegisterEmailHint;

  /// No description provided for @authRegisterPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get authRegisterPhoneLabel;

  /// No description provided for @authRegisterPhoneHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu teléfono'**
  String get authRegisterPhoneHint;

  /// No description provided for @authRegisterPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authRegisterPasswordLabel;

  /// No description provided for @authRegisterPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get authRegisterPasswordHint;

  /// No description provided for @authRegisterConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authRegisterConfirmPasswordLabel;

  /// No description provided for @authRegisterConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get authRegisterConfirmPasswordHint;

  /// No description provided for @authRegisterAcceptTermsPrefix.
  ///
  /// In es, this message translates to:
  /// **'Acepto '**
  String get authRegisterAcceptTermsPrefix;

  /// No description provided for @authRegisterAcceptTermsLink.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get authRegisterAcceptTermsLink;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get authRegisterSubmit;

  /// No description provided for @authRegisterHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authRegisterHaveAccount;

  /// No description provided for @authRegisterLoginAction.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authRegisterLoginAction;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In es, this message translates to:
  /// **'Registro exitoso. Revisa tu correo para confirmar tu cuenta.'**
  String get authRegisterSuccess;

  /// No description provided for @authEmailConfirmedLoginMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu correo fue confirmado. Ya puedes iniciar sesión.'**
  String get authEmailConfirmedLoginMessage;

  /// No description provided for @authTermsRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar términos y condiciones.'**
  String get authTermsRequired;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'La sesión ha expirado. Inicia sesión nuevamente.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no tiene permisos para realizar esta acción.'**
  String get authErrorUnauthorized;

  /// No description provided for @authErrorInvalidAuthResponse.
  ///
  /// In es, this message translates to:
  /// **'No fue posible validar la respuesta de autenticación.'**
  String get authErrorInvalidAuthResponse;

  /// No description provided for @authErrorUserProfileNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el perfil asociado a esta cuenta.'**
  String get authErrorUserProfileNotFound;

  /// No description provided for @authErrorUndefinedUserRole.
  ///
  /// In es, this message translates to:
  /// **'No fue posible determinar el rol del usuario.'**
  String get authErrorUndefinedUserRole;

  /// No description provided for @authErrorUnconfirmedEmail.
  ///
  /// In es, this message translates to:
  /// **'Debes confirmar tu correo antes de iniciar sesión.'**
  String get authErrorUnconfirmedEmail;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya se encuentra registrado.'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorInvalidRegisterResponse.
  ///
  /// In es, this message translates to:
  /// **'No fue posible completar el registro en este momento.'**
  String get authErrorInvalidRegisterResponse;

  /// No description provided for @authErrorEmailNotConfirmedRegister.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya existe, pero debes confirmar tu correo.'**
  String get authErrorEmailNotConfirmedRegister;

  /// No description provided for @authErrorAccountAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya existe. Inicia sesión.'**
  String get authErrorAccountAlreadyExists;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo ingresado no es válido.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no cumple los requisitos mínimos.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Has excedido el número de intentos permitidos. Intenta nuevamente en {remaining}.'**
  String authErrorRateLimit(Object remaining);

  /// No description provided for @authErrorRateLimitFallbackRemaining.
  ///
  /// In es, this message translates to:
  /// **'unos segundos'**
  String get authErrorRateLimitFallbackRemaining;

  /// No description provided for @authErrorRegisterRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Se alcanzó el límite de intentos de registro. Intenta nuevamente en unos minutos.'**
  String get authErrorRegisterRateLimit;

  /// No description provided for @authErrorRegisterUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No fue posible completar el registro. Intenta nuevamente.'**
  String get authErrorRegisterUnexpected;

  /// No description provided for @authErrorSessionRestoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No fue posible restaurar la sesión del usuario.'**
  String get authErrorSessionRestoreFailed;

  /// No description provided for @authErrorLocalSessionRecoveryFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar la sesión guardada en este dispositivo.'**
  String get authErrorLocalSessionRecoveryFailed;

  /// No description provided for @authErrorNetworkUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión a internet e intenta nuevamente.'**
  String get authErrorNetworkUnavailable;

  /// No description provided for @authErrorRequestTimeout.
  ///
  /// In es, this message translates to:
  /// **'La solicitud tardó demasiado. Verifica tu conexión e inténtalo nuevamente.'**
  String get authErrorRequestTimeout;

  /// No description provided for @authErrorServer.
  ///
  /// In es, this message translates to:
  /// **'El servicio no está disponible en este momento. Intenta nuevamente más tarde.'**
  String get authErrorServer;

  /// No description provided for @authErrorFallback.
  ///
  /// In es, this message translates to:
  /// **'No fue posible completar la operación. Intenta nuevamente.'**
  String get authErrorFallback;

  /// No description provided for @authTermsPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get authTermsPageTitle;

  /// No description provided for @authTermsPageBody.
  ///
  /// In es, this message translates to:
  /// **'TÉRMINOS Y CONDICIONES DE USO\n\nBienvenido a Autolab. Al acceder y utilizar esta aplicación, aceptas los siguientes términos y condiciones. Si no estás de acuerdo con alguno de ellos, te recomendamos no utilizar la app.\n\n1. USO DE LA APLICACIÓN\nAutolab es una plataforma que permite a los usuarios encontrar talleres mecánicos cercanos, consultar información y gestionar servicios relacionados con su vehículo.\n\nEl usuario se compromete a utilizar la aplicación de manera responsable, respetando las leyes vigentes y evitando cualquier uso indebido.\n\n2. REGISTRO DE USUARIO\nPara acceder a ciertas funcionalidades, es necesario registrarse proporcionando información veraz y actualizada. El usuario es responsable de mantener la confidencialidad de sus credenciales.\n\n3. PRIVACIDAD Y DATOS\nLa aplicación puede recopilar datos como nombre, correo electrónico, ubicación y número telefónico con el fin de mejorar la experiencia del usuario.\n\nEstos datos no serán compartidos con terceros sin consentimiento, salvo cuando sea requerido por ley.\n\n4. GEOLOCALIZACIÓN\nAutolab puede solicitar acceso a tu ubicación para mostrar talleres cercanos. El usuario puede aceptar o rechazar este permiso en cualquier momento desde la configuración del dispositivo.\n\n5. RESPONSABILIDAD\nAutolab actúa como intermediario entre el usuario y los talleres. No se hace responsable por la calidad del servicio brindado por terceros.\n\n6. MODIFICACIONES\nNos reservamos el derecho de modificar estos términos en cualquier momento. Se recomienda revisar esta sección periódicamente.\n\n7. ACEPTACIÓN\nAl utilizar la aplicación, el usuario acepta estos términos y condiciones en su totalidad.\n\nÚltima actualización: 2026'**
  String get authTermsPageBody;

  /// No description provided for @validationNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio.'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 3 caracteres.'**
  String get validationNameTooShort;

  /// No description provided for @validationEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es obligatorio.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In es, this message translates to:
  /// **'El teléfono es obligatorio.'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un teléfono válido.'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get validationPasswordTooShort;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma la contraseña.'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @routerInvalidWorkshopId.
  ///
  /// In es, this message translates to:
  /// **'ID de taller no válido'**
  String get routerInvalidWorkshopId;

  /// No description provided for @navigationHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// No description provided for @navigationMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navigationMap;

  /// No description provided for @navigationSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navigationSearch;

  /// No description provided for @navigationCart.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get navigationCart;

  /// No description provided for @navigationCartComingSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Carrito próximamente'**
  String get navigationCartComingSoonTitle;

  /// No description provided for @navigationCartComingSoonMessage.
  ///
  /// In es, this message translates to:
  /// **'Muy pronto podrás revisar tus productos desde aquí.'**
  String get navigationCartComingSoonMessage;

  /// No description provided for @navigationProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi garaje'**
  String get navigationProfile;

  /// No description provided for @customerOnboardingSlideVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu vehículo\nnuestra prioridad'**
  String get customerOnboardingSlideVehicleTitle;

  /// No description provided for @customerOnboardingSlideVehicleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios, productos y talleres confiables cerca de ti.'**
  String get customerOnboardingSlideVehicleSubtitle;

  /// No description provided for @customerOnboardingSlideBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda en\npocos pasos'**
  String get customerOnboardingSlideBookingTitle;

  /// No description provided for @customerOnboardingSlideBookingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reserva citas con talleres disponibles sin perder tiempo.'**
  String get customerOnboardingSlideBookingSubtitle;

  /// No description provided for @customerOnboardingSlideSearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Encuentra lo que\ntu carro necesita'**
  String get customerOnboardingSlideSearchTitle;

  /// No description provided for @customerOnboardingSlideSearchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora servicios y productos pensados para tu vehículo.'**
  String get customerOnboardingSlideSearchSubtitle;

  /// No description provided for @customerOnboardingSlideOrganizedTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo más claro\ny organizado'**
  String get customerOnboardingSlideOrganizedTitle;

  /// No description provided for @customerOnboardingSlideOrganizedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta tus citas, talleres y datos desde un solo lugar.'**
  String get customerOnboardingSlideOrganizedSubtitle;

  /// No description provided for @customerOnboardingStartAction.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get customerOnboardingStartAction;

  /// No description provided for @searchBarHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en Autolab'**
  String get searchBarHint;

  /// No description provided for @workshopSearchClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get workshopSearchClearTooltip;

  /// No description provided for @workshopSearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Talleres'**
  String get workshopSearchTitle;

  /// No description provided for @workshopSearchRecentTitle.
  ///
  /// In es, this message translates to:
  /// **'Búsquedas recientes'**
  String get workshopSearchRecentTitle;

  /// No description provided for @workshopSearchRecentClearAction.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get workshopSearchRecentClearAction;

  /// No description provided for @workshopSearchSuggestedTitle.
  ///
  /// In es, this message translates to:
  /// **'Búsquedas sugeridas'**
  String get workshopSearchSuggestedTitle;

  /// No description provided for @workshopSearchStartMessage.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre, descripción o ubicación de un taller para encontrarlo más rápido.'**
  String get workshopSearchStartMessage;

  /// No description provided for @workshopSearchNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos talleres que coincidan con tu búsqueda.'**
  String get workshopSearchNoResults;

  /// No description provided for @workshopSearchProductResults.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 resultado para \"{query}\"} other{{count} resultados para \"{query}\"}}'**
  String workshopSearchProductResults(num count, Object query);

  /// No description provided for @workshopSearchHomeDelivery.
  ///
  /// In es, this message translates to:
  /// **'A domicilio'**
  String get workshopSearchHomeDelivery;

  /// No description provided for @workshopSearchInWorkshop.
  ///
  /// In es, this message translates to:
  /// **'En taller'**
  String get workshopSearchInWorkshop;

  /// No description provided for @adminHomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel administrativo'**
  String get adminHomeTitle;

  /// No description provided for @adminHomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vista inicial para coordinación interna de Autolab.'**
  String get adminHomeSubtitle;

  /// No description provided for @adminHomeHeroLabel.
  ///
  /// In es, this message translates to:
  /// **'Operación del día'**
  String get adminHomeHeroLabel;

  /// No description provided for @adminHomeHeroValue.
  ///
  /// In es, this message translates to:
  /// **'Supervisa ingresos, agenda y seguimiento del taller desde un solo lugar.'**
  String get adminHomeHeroValue;

  /// No description provided for @adminHomeSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get adminHomeSummaryTitle;

  /// No description provided for @adminHomeQuickActionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Accesos rápidos'**
  String get adminHomeQuickActionsTitle;

  /// No description provided for @adminHomeCurrentStatusTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado actual'**
  String get adminHomeCurrentStatusTitle;

  /// No description provided for @adminHomeLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get adminHomeLogout;

  /// No description provided for @adminHomeHighlightAgendaTitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda operativa'**
  String get adminHomeHighlightAgendaTitle;

  /// No description provided for @adminHomeHighlightAgendaDescription.
  ///
  /// In es, this message translates to:
  /// **'Aquí podremos mostrar entradas programadas, vehículos en proceso y entregas pendientes.'**
  String get adminHomeHighlightAgendaDescription;

  /// No description provided for @adminHomeHighlightTrackingTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento del taller'**
  String get adminHomeHighlightTrackingTitle;

  /// No description provided for @adminHomeHighlightTrackingDescription.
  ///
  /// In es, this message translates to:
  /// **'El diseño ya separa el espacio donde luego conectaremos estados de servicio, técnicos y tiempos de atención.'**
  String get adminHomeHighlightTrackingDescription;

  /// No description provided for @adminHomeHighlightCustomersTitle.
  ///
  /// In es, this message translates to:
  /// **'Relación con clientes'**
  String get adminHomeHighlightCustomersTitle;

  /// No description provided for @adminHomeHighlightCustomersDescription.
  ///
  /// In es, this message translates to:
  /// **'También queda listo para incorporar alertas de aprobación, historial y comunicación post-servicio.'**
  String get adminHomeHighlightCustomersDescription;

  /// No description provided for @adminHomeQuickActionRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar ingreso'**
  String get adminHomeQuickActionRegisterTitle;

  /// No description provided for @adminHomeQuickActionRegisterDescription.
  ///
  /// In es, this message translates to:
  /// **'Crear una nueva recepción de vehículo.'**
  String get adminHomeQuickActionRegisterDescription;

  /// No description provided for @adminHomeQuickActionOrdersTitle.
  ///
  /// In es, this message translates to:
  /// **'Ver órdenes abiertas'**
  String get adminHomeQuickActionOrdersTitle;

  /// No description provided for @adminHomeQuickActionOrdersDescription.
  ///
  /// In es, this message translates to:
  /// **'Consultar trabajos que siguen en ejecución.'**
  String get adminHomeQuickActionOrdersDescription;

  /// No description provided for @adminHomeQuickActionDeliveriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar entregas'**
  String get adminHomeQuickActionDeliveriesTitle;

  /// No description provided for @adminHomeQuickActionDeliveriesDescription.
  ///
  /// In es, this message translates to:
  /// **'Identificar unidades listas para salida.'**
  String get adminHomeQuickActionDeliveriesDescription;

  /// No description provided for @adminHomeStatusCapacityLabel.
  ///
  /// In es, this message translates to:
  /// **'Capacidad del taller'**
  String get adminHomeStatusCapacityLabel;

  /// No description provided for @adminHomeStatusCapacityCaption.
  ///
  /// In es, this message translates to:
  /// **'Carga saludable'**
  String get adminHomeStatusCapacityCaption;

  /// No description provided for @adminHomeStatusCriticalDeliveriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Entregas críticas'**
  String get adminHomeStatusCriticalDeliveriesLabel;

  /// No description provided for @adminHomeStatusCriticalDeliveriesCaption.
  ///
  /// In es, this message translates to:
  /// **'Revisión prioritaria'**
  String get adminHomeStatusCriticalDeliveriesCaption;

  /// No description provided for @adminHomeStatusPendingApprovalsLabel.
  ///
  /// In es, this message translates to:
  /// **'Aprobaciones pendientes'**
  String get adminHomeStatusPendingApprovalsLabel;

  /// No description provided for @adminHomeStatusPendingApprovalsCaption.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta'**
  String get adminHomeStatusPendingApprovalsCaption;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get profileAccountTitle;

  /// No description provided for @profileAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Administra tu sesión y revisa la información principal de tu perfil desde este apartado.'**
  String get profileAccountSubtitle;

  /// No description provided for @profileSessionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get profileSessionTitle;

  /// No description provided for @profileSessionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cierra tu sesión cuando quieras desde aquí.'**
  String get profileSessionSubtitle;

  /// No description provided for @profileLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogout;

  /// No description provided for @profileAppointmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis citas'**
  String get profileAppointmentsTitle;

  /// No description provided for @profileAppointmentsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta tus citas próximas, pasadas y canceladas.'**
  String get profileAppointmentsSubtitle;

  /// No description provided for @profileDarkModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get profileDarkModeTitle;

  /// No description provided for @profileDarkModeEnabled.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get profileDarkModeEnabled;

  /// No description provided for @profileDarkModeDisabled.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get profileDarkModeDisabled;

  /// No description provided for @garageTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Garaje'**
  String get garageTitle;

  /// No description provided for @garageDefaultCustomerName.
  ///
  /// In es, this message translates to:
  /// **'Cliente Autolab'**
  String get garageDefaultCustomerName;

  /// No description provided for @garageGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {displayName}'**
  String garageGreeting(Object displayName);

  /// No description provided for @garageWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a tu garaje'**
  String get garageWelcomeSubtitle;

  /// No description provided for @garageChangeProfilePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get garageChangeProfilePhotoTitle;

  /// No description provided for @garageChooseFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get garageChooseFromGallery;

  /// No description provided for @garageCloseAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get garageCloseAction;

  /// No description provided for @garageQuickAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Accesos Rápidos'**
  String get garageQuickAccessTitle;

  /// No description provided for @garageOrders.
  ///
  /// In es, this message translates to:
  /// **'Mis pedidos'**
  String get garageOrders;

  /// No description provided for @loyaltyProgramsTitle.
  ///
  /// In es, this message translates to:
  /// **'Programas de lealtad'**
  String get loyaltyProgramsTitle;

  /// No description provided for @loyaltyProgramsComingSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Muy pronto'**
  String get loyaltyProgramsComingSoonTitle;

  /// No description provided for @loyaltyProgramsComingSoonMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando beneficios y programas especiales para tu vehículo.'**
  String get loyaltyProgramsComingSoonMessage;

  /// No description provided for @loyaltyProgramsBackToGarage.
  ///
  /// In es, this message translates to:
  /// **'Volver a mi garaje'**
  String get loyaltyProgramsBackToGarage;

  /// No description provided for @garageHistory.
  ///
  /// In es, this message translates to:
  /// **'Mis órdenes'**
  String get garageHistory;

  /// No description provided for @garageManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión'**
  String get garageManagementTitle;

  /// No description provided for @garageFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get garageFavorites;

  /// No description provided for @garageAddresses.
  ///
  /// In es, this message translates to:
  /// **'Direcciones'**
  String get garageAddresses;

  /// No description provided for @garagePaymentMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get garagePaymentMethods;

  /// No description provided for @garageSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get garageSettings;

  /// No description provided for @garageSupportTitle.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get garageSupportTitle;

  /// No description provided for @garageHelpCenter.
  ///
  /// In es, this message translates to:
  /// **'Centro de ayuda'**
  String get garageHelpCenter;

  /// No description provided for @garageContactSupport.
  ///
  /// In es, this message translates to:
  /// **'Contactar soporte'**
  String get garageContactSupport;

  /// No description provided for @garageAboutUs.
  ///
  /// In es, this message translates to:
  /// **'Quiénes somos'**
  String get garageAboutUs;

  /// No description provided for @garageActiveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo activo'**
  String get garageActiveVehicle;

  /// No description provided for @myAppointmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis citas'**
  String get myAppointmentsTitle;

  /// No description provided for @myAppointmentsNotificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get myAppointmentsNotificationsTooltip;

  /// No description provided for @myAppointmentsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta tus reservas de servicios'**
  String get myAppointmentsSubtitle;

  /// No description provided for @myAppointmentsLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus citas'**
  String get myAppointmentsLoadErrorTitle;

  /// No description provided for @myAppointmentsRetryMessage.
  ///
  /// In es, this message translates to:
  /// **'Intenta nuevamente en unos segundos.'**
  String get myAppointmentsRetryMessage;

  /// No description provided for @myAppointmentsRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get myAppointmentsRetryAction;

  /// No description provided for @myAppointmentsSearchWorkshopsAction.
  ///
  /// In es, this message translates to:
  /// **'Buscar talleres'**
  String get myAppointmentsSearchWorkshopsAction;

  /// No description provided for @myAppointmentsUpcomingEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas próximas'**
  String get myAppointmentsUpcomingEmptyTitle;

  /// No description provided for @myAppointmentsPastEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas pasadas'**
  String get myAppointmentsPastEmptyTitle;

  /// No description provided for @myAppointmentsCanceledEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas canceladas'**
  String get myAppointmentsCanceledEmptyTitle;

  /// No description provided for @myAppointmentsUpcomingEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando reserves un servicio en un taller, aparecerá aquí.'**
  String get myAppointmentsUpcomingEmptyMessage;

  /// No description provided for @myAppointmentsPastEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus servicios completados o vencidos aparecerán aquí.'**
  String get myAppointmentsPastEmptyMessage;

  /// No description provided for @myAppointmentsCanceledEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Las reservas canceladas aparecerán en este apartado.'**
  String get myAppointmentsCanceledEmptyMessage;

  /// No description provided for @myAppointmentsUpcomingTab.
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get myAppointmentsUpcomingTab;

  /// No description provided for @myAppointmentsPastTab.
  ///
  /// In es, this message translates to:
  /// **'Finalizadas'**
  String get myAppointmentsPastTab;

  /// No description provided for @myAppointmentsCanceledTab.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get myAppointmentsCanceledTab;

  /// No description provided for @myAppointmentsNewAppointmentPrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas agendar una nueva cita?'**
  String get myAppointmentsNewAppointmentPrompt;

  /// No description provided for @myAppointmentsStatusCanceled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get myAppointmentsStatusCanceled;

  /// No description provided for @myAppointmentsStatusNoShow.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get myAppointmentsStatusNoShow;

  /// No description provided for @myAppointmentsStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get myAppointmentsStatusCompleted;

  /// No description provided for @myAppointmentsStatusCheckedIn.
  ///
  /// In es, this message translates to:
  /// **'Registrada'**
  String get myAppointmentsStatusCheckedIn;

  /// No description provided for @myAppointmentsStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get myAppointmentsStatusInProgress;

  /// No description provided for @myAppointmentsStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get myAppointmentsStatusExpired;

  /// No description provided for @myAppointmentsStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Programada'**
  String get myAppointmentsStatusConfirmed;

  /// No description provided for @myAppointmentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de cita'**
  String get myAppointmentDetailTitle;

  /// No description provided for @myAppointmentDetailPlate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get myAppointmentDetailPlate;

  /// No description provided for @myAppointmentDetailVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get myAppointmentDetailVehicle;

  /// No description provided for @myAppointmentDetailDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get myAppointmentDetailDate;

  /// No description provided for @myAppointmentDetailTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get myAppointmentDetailTime;

  /// No description provided for @myAppointmentDetailTotal.
  ///
  /// In es, this message translates to:
  /// **'Total a pagar'**
  String get myAppointmentDetailTotal;

  /// No description provided for @myAppointmentDetailItems.
  ///
  /// In es, this message translates to:
  /// **'Productos y servicios'**
  String get myAppointmentDetailItems;

  /// No description provided for @myAppointmentDetailPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get myAppointmentDetailPaymentMethod;

  /// No description provided for @myAppointmentDetailNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get myAppointmentDetailNotAvailable;

  /// No description provided for @myAppointmentRescheduleAction.
  ///
  /// In es, this message translates to:
  /// **'Reagendar'**
  String get myAppointmentRescheduleAction;

  /// No description provided for @myAppointmentRescheduleSoon.
  ///
  /// In es, this message translates to:
  /// **'La opción de reagendar estará disponible pronto.'**
  String get myAppointmentRescheduleSoon;

  /// No description provided for @myAppointmentRescheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona nueva fecha'**
  String get myAppointmentRescheduleTitle;

  /// No description provided for @myAppointmentRescheduleCalendarMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get myAppointmentRescheduleCalendarMonth;

  /// No description provided for @myAppointmentRescheduleAvailableHours.
  ///
  /// In es, this message translates to:
  /// **'Horas disponibles'**
  String get myAppointmentRescheduleAvailableHours;

  /// No description provided for @myAppointmentRescheduleConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nueva fecha'**
  String get myAppointmentRescheduleConfirm;

  /// No description provided for @myAppointmentRescheduleLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando horarios disponibles'**
  String get myAppointmentRescheduleLoading;

  /// No description provided for @myAppointmentRescheduleLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los horarios. Intenta nuevamente.'**
  String get myAppointmentRescheduleLoadError;

  /// No description provided for @myAppointmentRescheduleNoHours.
  ///
  /// In es, this message translates to:
  /// **'No hay horarios disponibles para esta fecha.'**
  String get myAppointmentRescheduleNoHours;

  /// No description provided for @myAppointmentRescheduleSelectHour.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una hora disponible.'**
  String get myAppointmentRescheduleSelectHour;

  /// No description provided for @myAppointmentRescheduleFailure.
  ///
  /// In es, this message translates to:
  /// **'No pudimos reagendar la cita. Intenta nuevamente.'**
  String get myAppointmentRescheduleFailure;

  /// No description provided for @myAppointmentCancelBusyMessage.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una cancelación en proceso.'**
  String get myAppointmentCancelBusyMessage;

  /// No description provided for @myAppointmentRescheduleBusyMessage.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un reagendado en proceso.'**
  String get myAppointmentRescheduleBusyMessage;

  /// No description provided for @myAppointmentRescheduleSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Cita reagendada!'**
  String get myAppointmentRescheduleSuccessTitle;

  /// No description provided for @myAppointmentRescheduleSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu cita ha sido actualizada correctamente.'**
  String get myAppointmentRescheduleSuccessMessage;

  /// No description provided for @myAppointmentRescheduleSuccessAction.
  ///
  /// In es, this message translates to:
  /// **'Ver mis citas'**
  String get myAppointmentRescheduleSuccessAction;

  /// No description provided for @myAppointmentCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar cita'**
  String get myAppointmentCancelAction;

  /// No description provided for @myAppointmentCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar cita'**
  String get myAppointmentCancelTitle;

  /// No description provided for @myAppointmentCancelReasonQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué deseas cancelar esta cita?'**
  String get myAppointmentCancelReasonQuestion;

  /// No description provided for @myAppointmentCancelReasonNoNeed.
  ///
  /// In es, this message translates to:
  /// **'Ya no necesito el servicio'**
  String get myAppointmentCancelReasonNoNeed;

  /// No description provided for @myAppointmentCancelReasonChangedWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Cambié de taller'**
  String get myAppointmentCancelReasonChangedWorkshop;

  /// No description provided for @myAppointmentCancelReasonBookingError.
  ///
  /// In es, this message translates to:
  /// **'Error en la reserva'**
  String get myAppointmentCancelReasonBookingError;

  /// No description provided for @myAppointmentCancelReasonCannotAttend.
  ///
  /// In es, this message translates to:
  /// **'No podré asistir'**
  String get myAppointmentCancelReasonCannotAttend;

  /// No description provided for @myAppointmentCancelReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get myAppointmentCancelReasonOther;

  /// No description provided for @myAppointmentCancelCommentsHint.
  ///
  /// In es, this message translates to:
  /// **'Comentarios (opcional)'**
  String get myAppointmentCancelCommentsHint;

  /// No description provided for @myAppointmentCancelContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get myAppointmentCancelContinue;

  /// No description provided for @myAppointmentCancelConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas cancelar esta cita?'**
  String get myAppointmentCancelConfirmTitle;

  /// No description provided for @myAppointmentCancelConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get myAppointmentCancelConfirmMessage;

  /// No description provided for @myAppointmentCancelConfirmNo.
  ///
  /// In es, this message translates to:
  /// **'No, volver'**
  String get myAppointmentCancelConfirmNo;

  /// No description provided for @myAppointmentCancelConfirmYes.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get myAppointmentCancelConfirmYes;

  /// No description provided for @myAppointmentCancelSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Cita cancelada!'**
  String get myAppointmentCancelSuccessTitle;

  /// No description provided for @myAppointmentCancelSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu cita ha sido cancelada correctamente.'**
  String get myAppointmentCancelSuccessMessage;

  /// No description provided for @myAppointmentCancelSuccessAction.
  ///
  /// In es, this message translates to:
  /// **'Volver a mis citas'**
  String get myAppointmentCancelSuccessAction;

  /// No description provided for @myAppointmentCancelFailure.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la cita. Intenta nuevamente.'**
  String get myAppointmentCancelFailure;

  /// No description provided for @vehiclesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis vehículos'**
  String get vehiclesTitle;

  /// No description provided for @vehiclesViewAllAction.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get vehiclesViewAllAction;

  /// No description provided for @homeActivateVehicleMessage.
  ///
  /// In es, this message translates to:
  /// **'Activa tu vehículo'**
  String get homeActivateVehicleMessage;

  /// No description provided for @vehiclesProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Administra los vehículos que usas para reservar citas.'**
  String get vehiclesProfileSubtitle;

  /// No description provided for @vehiclesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus vehículos una sola vez y selecciónalos al agendar en cualquier taller.'**
  String get vehiclesSubtitle;

  /// No description provided for @vehiclesAddAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get vehiclesAddAction;

  /// No description provided for @vehiclesChangeImageAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get vehiclesChangeImageAction;

  /// No description provided for @vehiclesEditAction.
  ///
  /// In es, this message translates to:
  /// **'Editar vehículo'**
  String get vehiclesEditAction;

  /// No description provided for @vehiclesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes vehículos guardados.'**
  String get vehiclesEmpty;

  /// No description provided for @vehiclesLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus vehículos. Intenta nuevamente.'**
  String get vehiclesLoadFailed;

  /// No description provided for @vehiclesFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get vehiclesFormTitle;

  /// No description provided for @vehiclesEditFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar vehículo'**
  String get vehiclesEditFormTitle;

  /// No description provided for @vehiclesPlateLabel.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get vehiclesPlateLabel;

  /// No description provided for @vehiclesPlateRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la placa del vehículo.'**
  String get vehiclesPlateRequired;

  /// No description provided for @vehiclesTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get vehiclesTypeLabel;

  /// No description provided for @vehiclesTypeCar.
  ///
  /// In es, this message translates to:
  /// **'Automóvil'**
  String get vehiclesTypeCar;

  /// No description provided for @vehiclesTypeMotorcycle.
  ///
  /// In es, this message translates to:
  /// **'Motocicleta'**
  String get vehiclesTypeMotorcycle;

  /// No description provided for @vehiclesTypePickup.
  ///
  /// In es, this message translates to:
  /// **'Pickup'**
  String get vehiclesTypePickup;

  /// No description provided for @vehiclesTypeSuv.
  ///
  /// In es, this message translates to:
  /// **'SUV'**
  String get vehiclesTypeSuv;

  /// No description provided for @vehiclesTypeTruck.
  ///
  /// In es, this message translates to:
  /// **'Camión'**
  String get vehiclesTypeTruck;

  /// No description provided for @vehiclesBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get vehiclesBrandLabel;

  /// No description provided for @vehiclesModelLabel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get vehiclesModelLabel;

  /// No description provided for @vehiclesYearLabel.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get vehiclesYearLabel;

  /// No description provided for @vehiclesColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get vehiclesColorLabel;

  /// No description provided for @vehiclesFuelLabel.
  ///
  /// In es, this message translates to:
  /// **'Combustible'**
  String get vehiclesFuelLabel;

  /// No description provided for @vehiclesFuelGasoline.
  ///
  /// In es, this message translates to:
  /// **'Gasolina'**
  String get vehiclesFuelGasoline;

  /// No description provided for @vehiclesFuelDiesel.
  ///
  /// In es, this message translates to:
  /// **'Diésel'**
  String get vehiclesFuelDiesel;

  /// No description provided for @vehiclesFuelElectric.
  ///
  /// In es, this message translates to:
  /// **'Eléctrico'**
  String get vehiclesFuelElectric;

  /// No description provided for @vehiclesFuelHybrid.
  ///
  /// In es, this message translates to:
  /// **'Híbrido'**
  String get vehiclesFuelHybrid;

  /// No description provided for @vehiclesTransmissionLabel.
  ///
  /// In es, this message translates to:
  /// **'Transmisión'**
  String get vehiclesTransmissionLabel;

  /// No description provided for @vehiclesTransmissionManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get vehiclesTransmissionManual;

  /// No description provided for @vehiclesTransmissionAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automática'**
  String get vehiclesTransmissionAutomatic;

  /// No description provided for @vehiclesSaveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar vehículo'**
  String get vehiclesSaveAction;

  /// No description provided for @vehiclesNextAction.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get vehiclesNextAction;

  /// No description provided for @vehiclesSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el vehículo. Revisa la información e inténtalo de nuevo.'**
  String get vehiclesSaveFailed;

  /// No description provided for @vehiclesPlateAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Esta placa ya está registrada en tus vehículos. Selecciona ese vehículo de la lista o elimina el registro anterior.'**
  String get vehiclesPlateAlreadyExists;

  /// No description provided for @vehiclesDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vehículo'**
  String get vehiclesDeleteTitle;

  /// No description provided for @vehiclesDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres eliminar el vehículo {plate} de tus vehículos?'**
  String vehiclesDeleteMessage(String plate);

  /// No description provided for @vehiclesCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get vehiclesCancelAction;

  /// No description provided for @vehiclesDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get vehiclesDeleteAction;

  /// No description provided for @vehiclesDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar el vehículo. Intenta nuevamente.'**
  String get vehiclesDeleteFailed;

  /// No description provided for @locationHeaderEyebrowDeliverNow.
  ///
  /// In es, this message translates to:
  /// **'Entregar ahora'**
  String get locationHeaderEyebrowDeliverNow;

  /// No description provided for @locationHeaderEyebrowConfirmingAccess.
  ///
  /// In es, this message translates to:
  /// **'Confirmando acceso'**
  String get locationHeaderEyebrowConfirmingAccess;

  /// No description provided for @locationHeaderEyebrowLoading.
  ///
  /// In es, this message translates to:
  /// **'Buscando cerca de ti'**
  String get locationHeaderEyebrowLoading;

  /// No description provided for @locationHeaderEyebrowPermission.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación'**
  String get locationHeaderEyebrowPermission;

  /// No description provided for @locationHeaderEyebrowGpsOff.
  ///
  /// In es, this message translates to:
  /// **'Ubicación desactivada'**
  String get locationHeaderEyebrowGpsOff;

  /// No description provided for @locationHeaderEyebrowRestricted.
  ///
  /// In es, this message translates to:
  /// **'Ubicación restringida'**
  String get locationHeaderEyebrowRestricted;

  /// No description provided for @locationHeaderEyebrowError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu zona'**
  String get locationHeaderEyebrowError;

  /// No description provided for @locationHeaderTitleChooseAddress.
  ///
  /// In es, this message translates to:
  /// **'Elegir dirección'**
  String get locationHeaderTitleChooseAddress;

  /// No description provided for @locationHeaderTitleOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get locationHeaderTitleOpenSettings;

  /// No description provided for @locationHeaderTitleEnableGps.
  ///
  /// In es, this message translates to:
  /// **'Encender GPS'**
  String get locationHeaderTitleEnableGps;

  /// No description provided for @locationHeaderTitleUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Ubicación no disponible'**
  String get locationHeaderTitleUnavailable;

  /// No description provided for @locationHeaderTitleConfirmAccess.
  ///
  /// In es, this message translates to:
  /// **'Confirma el acceso a tu ubicación'**
  String get locationHeaderTitleConfirmAccess;

  /// No description provided for @locationHeaderTitleError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu dirección'**
  String get locationHeaderTitleError;

  /// No description provided for @locationHeaderTitleLoading.
  ///
  /// In es, this message translates to:
  /// **'Buscando tu ubicación actual'**
  String get locationHeaderTitleLoading;

  /// No description provided for @locationHeaderTitleSuccessFallback.
  ///
  /// In es, this message translates to:
  /// **'Ubicación detectada'**
  String get locationHeaderTitleSuccessFallback;

  /// No description provided for @locationHeaderSubtitleChooseAddress.
  ///
  /// In es, this message translates to:
  /// **'Usa tu ubicación actual para descubrir talleres y servicios cercanos.'**
  String get locationHeaderSubtitleChooseAddress;

  /// No description provided for @locationHeaderSubtitleOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos que habilites el permiso desde la configuración del teléfono.'**
  String get locationHeaderSubtitleOpenSettings;

  /// No description provided for @locationHeaderSubtitleEnableGps.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación del dispositivo para ver resultados cercanos.'**
  String get locationHeaderSubtitleEnableGps;

  /// No description provided for @locationHeaderSubtitleConfirmAccess.
  ///
  /// In es, this message translates to:
  /// **'Estamos esperando tu respuesta para poder ubicar tu zona de entrega.'**
  String get locationHeaderSubtitleConfirmAccess;

  /// No description provided for @locationHeaderSubtitleLoading.
  ///
  /// In es, this message translates to:
  /// **'Estamos consultando la ubicación del dispositivo para mostrarte talleres cercanos.'**
  String get locationHeaderSubtitleLoading;

  /// No description provided for @locationHeaderSubtitleErrorFallback.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo en unos segundos.'**
  String get locationHeaderSubtitleErrorFallback;

  /// No description provided for @locationHeaderSubtitleRestrictedFallback.
  ///
  /// In es, this message translates to:
  /// **'La ubicación no está disponible en este dispositivo.'**
  String get locationHeaderSubtitleRestrictedFallback;

  /// No description provided for @locationErrorPermissionRestricted.
  ///
  /// In es, this message translates to:
  /// **'La ubicación está restringida en este dispositivo.'**
  String get locationErrorPermissionRestricted;

  /// No description provided for @locationErrorPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Activa tu ubicación para ver talleres y servicios cercanos.'**
  String get locationErrorPermissionRequired;

  /// No description provided for @locationErrorServiceDisabled.
  ///
  /// In es, this message translates to:
  /// **'Enciende el GPS del dispositivo para continuar.'**
  String get locationErrorServiceDisabled;

  /// No description provided for @locationErrorActionFailed.
  ///
  /// In es, this message translates to:
  /// **'No fue posible completar la acción de ubicación. Intenta nuevamente.'**
  String get locationErrorActionFailed;

  /// No description provided for @locationErrorRequestTimeout.
  ///
  /// In es, this message translates to:
  /// **'La ubicación tardó demasiado en responder. Intenta nuevamente.'**
  String get locationErrorRequestTimeout;

  /// No description provided for @locationErrorInvalidCurrentLocation.
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener una ubicación válida. Intenta nuevamente.'**
  String get locationErrorInvalidCurrentLocation;

  /// No description provided for @locationErrorConfigurationIncomplete.
  ///
  /// In es, this message translates to:
  /// **'La ubicación no está disponible en este momento. Intenta más tarde.'**
  String get locationErrorConfigurationIncomplete;

  /// No description provided for @locationSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona dónde entregar'**
  String get locationSheetTitle;

  /// No description provided for @locationSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes usar tu ubicación actual o elegir una dirección guardada más adelante.'**
  String get locationSheetSubtitle;

  /// No description provided for @locationSheetCurrentLocationDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Usar ubicación actual'**
  String get locationSheetCurrentLocationDefaultTitle;

  /// No description provided for @locationSheetCurrentLocationDefaultSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa el GPS del teléfono para ver talleres y servicios cerca de ti.'**
  String get locationSheetCurrentLocationDefaultSubtitle;

  /// No description provided for @locationSheetCurrentLocationSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizar ubicación actual'**
  String get locationSheetCurrentLocationSuccessTitle;

  /// No description provided for @locationSheetCurrentLocationSuccessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Volver a consultar tu ubicación para actualizar los resultados.'**
  String get locationSheetCurrentLocationSuccessSubtitle;

  /// No description provided for @locationSheetCurrentLocationOpenSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get locationSheetCurrentLocationOpenSettingsTitle;

  /// No description provided for @locationSheetCurrentLocationOpenSettingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Habilita el permiso de ubicación desde la configuración del teléfono.'**
  String get locationSheetCurrentLocationOpenSettingsSubtitle;

  /// No description provided for @locationSheetCurrentLocationEnableGpsTitle.
  ///
  /// In es, this message translates to:
  /// **'Encender GPS'**
  String get locationSheetCurrentLocationEnableGpsTitle;

  /// No description provided for @locationSheetCurrentLocationEnableGpsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación del dispositivo para ver talleres cercanos.'**
  String get locationSheetCurrentLocationEnableGpsSubtitle;

  /// No description provided for @locationSheetCurrentLocationWaitingTitle.
  ///
  /// In es, this message translates to:
  /// **'Esperando permiso'**
  String get locationSheetCurrentLocationWaitingTitle;

  /// No description provided for @locationSheetCurrentLocationWaitingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estamos esperando tu respuesta para acceder a la ubicación.'**
  String get locationSheetCurrentLocationWaitingSubtitle;

  /// No description provided for @locationSheetWriteAddressTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribir dirección'**
  String get locationSheetWriteAddressTitle;

  /// No description provided for @locationSheetWriteAddressSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo conectamos en el siguiente paso del home.'**
  String get locationSheetWriteAddressSubtitle;

  /// No description provided for @locationSheetHomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get locationSheetHomeTitle;

  /// No description provided for @locationSheetWorkTitle.
  ///
  /// In es, this message translates to:
  /// **'Trabajo'**
  String get locationSheetWorkTitle;

  /// No description provided for @locationSheetSavedAddressSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Próximamente podrás guardar tus direcciones favoritas.'**
  String get locationSheetSavedAddressSubtitle;

  /// No description provided for @workshopsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Talleres cercanos'**
  String get workshopsSectionTitle;

  /// No description provided for @workshopsSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora opciones cercanas sin salir del home.'**
  String get workshopsSectionSubtitle;

  /// No description provided for @workshopsSectionViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get workshopsSectionViewAll;

  /// No description provided for @workshopsSectionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los talleres en este momento.'**
  String get workshopsSectionLoadError;

  /// No description provided for @workshopErrorLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los talleres en este momento.'**
  String get workshopErrorLoadFailed;

  /// No description provided for @workshopErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión para consultar los talleres cercanos.'**
  String get workshopErrorNetwork;

  /// No description provided for @workshopCardDistancePrefix.
  ///
  /// In es, this message translates to:
  /// **'A {distance}'**
  String workshopCardDistancePrefix(Object distance);

  /// No description provided for @workshopCardCoveragePrefix.
  ///
  /// In es, this message translates to:
  /// **'Cobertura {distance}'**
  String workshopCardCoveragePrefix(Object distance);

  /// No description provided for @workshopCardDescriptionFallback.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción disponible'**
  String get workshopCardDescriptionFallback;

  /// No description provided for @workshopProfileLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar el perfil del taller en este momento.'**
  String get workshopProfileLoadError;

  /// No description provided for @workshopProfileNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este taller.'**
  String get workshopProfileNotFound;

  /// No description provided for @workshopProfileScheduleAction.
  ///
  /// In es, this message translates to:
  /// **'Agendar cita'**
  String get workshopProfileScheduleAction;

  /// No description provided for @workshopProfileCallAction.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get workshopProfileCallAction;

  /// No description provided for @workshopProfileOpenLocationAction.
  ///
  /// In es, this message translates to:
  /// **'Abrir ubicación'**
  String get workshopProfileOpenLocationAction;

  /// No description provided for @workshopProfileDirectionsAction.
  ///
  /// In es, this message translates to:
  /// **'Dirígete ahí'**
  String get workshopProfileDirectionsAction;

  /// No description provided for @workshopProfileScheduleSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente podrás agendar una cita desde aquí.'**
  String get workshopProfileScheduleSoon;

  /// No description provided for @workshopProfileActionError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible abrir esta acción. Intenta nuevamente.'**
  String get workshopProfileActionError;

  /// No description provided for @workshopProfileDeliveryTab.
  ///
  /// In es, this message translates to:
  /// **'Entrega'**
  String get workshopProfileDeliveryTab;

  /// No description provided for @workshopProfilePickupTab.
  ///
  /// In es, this message translates to:
  /// **'Para llevar'**
  String get workshopProfilePickupTab;

  /// No description provided for @workshopProfileAboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca del taller'**
  String get workshopProfileAboutTitle;

  /// No description provided for @workshopProfileDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get workshopProfileDetailsTitle;

  /// No description provided for @workshopProfileHomeServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio a domicilio'**
  String get workshopProfileHomeServiceTitle;

  /// No description provided for @workshopProfileHomeServiceAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get workshopProfileHomeServiceAvailable;

  /// No description provided for @workshopProfileHomeServiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get workshopProfileHomeServiceUnavailable;

  /// No description provided for @workshopProfileMobileServiceLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicio móvil'**
  String get workshopProfileMobileServiceLabel;

  /// No description provided for @workshopProfileCoverageTitle.
  ///
  /// In es, this message translates to:
  /// **'Cobertura'**
  String get workshopProfileCoverageTitle;

  /// No description provided for @workshopProfileCoverageValue.
  ///
  /// In es, this message translates to:
  /// **'{distance} km de radio'**
  String workshopProfileCoverageValue(Object distance);

  /// No description provided for @workshopProfileCoverageAreaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Área de atención'**
  String get workshopProfileCoverageAreaSubtitle;

  /// No description provided for @workshopProfileCoverageUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Cobertura no disponible'**
  String get workshopProfileCoverageUnavailable;

  /// No description provided for @workshopProfilePhoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get workshopProfilePhoneTitle;

  /// No description provided for @workshopProfileServicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get workshopProfileServicesTitle;

  /// No description provided for @workshopProfileServicesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este taller aún no tiene servicios publicados.'**
  String get workshopProfileServicesEmpty;

  /// No description provided for @workshopProfileProductsTitle.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get workshopProfileProductsTitle;

  /// No description provided for @workshopProfileProductsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este taller aún no tiene productos publicados.'**
  String get workshopProfileProductsEmpty;

  /// No description provided for @workshopProfileProductSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar productos en este taller...'**
  String get workshopProfileProductSearchHint;

  /// No description provided for @workshopProfileProductsNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos productos que coincidan con tu búsqueda.'**
  String get workshopProfileProductsNoResults;

  /// No description provided for @workshopSearchProductsHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar producto o servicio'**
  String get workshopSearchProductsHint;

  /// No description provided for @workshopSearchProductsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos productos o servicios con esos filtros.'**
  String get workshopSearchProductsEmpty;

  /// No description provided for @workshopSearchProductsClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get workshopSearchProductsClearTooltip;

  /// No description provided for @workshopSearchProductsViewWorkshopTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver taller'**
  String get workshopSearchProductsViewWorkshopTooltip;

  /// No description provided for @workshopProfileBusinessHoursTitle.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get workshopProfileBusinessHoursTitle;

  /// No description provided for @workshopProfileBusinessHoursEmpty.
  ///
  /// In es, this message translates to:
  /// **'Horario no disponible'**
  String get workshopProfileBusinessHoursEmpty;

  /// No description provided for @workshopProfileClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get workshopProfileClosed;

  /// No description provided for @workshopProfileOpenUntil.
  ///
  /// In es, this message translates to:
  /// **'Abierto hasta las {time}'**
  String workshopProfileOpenUntil(Object time);

  /// No description provided for @workshopProfileUnknownDay.
  ///
  /// In es, this message translates to:
  /// **'Día no disponible'**
  String get workshopProfileUnknownDay;

  /// No description provided for @workshopProfilePaymentMethodsTitle.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get workshopProfilePaymentMethodsTitle;

  /// No description provided for @workshopProfilePaymentMethodsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago no disponibles.'**
  String get workshopProfilePaymentMethodsEmpty;

  /// No description provided for @workshopProfileCatalogTitle.
  ///
  /// In es, this message translates to:
  /// **'Explora el catálogo'**
  String get workshopProfileCatalogTitle;

  /// No description provided for @workshopProfileCatalogAllTab.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get workshopProfileCatalogAllTab;

  /// No description provided for @workshopProfileCatalogPopularTab.
  ///
  /// In es, this message translates to:
  /// **'Populares'**
  String get workshopProfileCatalogPopularTab;

  /// No description provided for @workshopProfileCatalogServicesTab.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get workshopProfileCatalogServicesTab;

  /// No description provided for @workshopProfileCatalogProductsTab.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get workshopProfileCatalogProductsTab;

  /// No description provided for @workshopProfileCatalogViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get workshopProfileCatalogViewAll;

  /// No description provided for @workshopProfileCatalogComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get workshopProfileCatalogComingSoon;

  /// No description provided for @workshopProfileProductsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los productos de este taller.'**
  String get workshopProfileProductsLoadError;

  /// No description provided for @serviceDetailWorkshopFallback.
  ///
  /// In es, this message translates to:
  /// **'Taller Autolab'**
  String get serviceDetailWorkshopFallback;

  /// No description provided for @serviceDetailDescriptionTitle.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get serviceDetailDescriptionTitle;

  /// No description provided for @serviceDetailDescriptionFallback.
  ///
  /// In es, this message translates to:
  /// **'Consulta los detalles de este servicio directamente con el taller.'**
  String get serviceDetailDescriptionFallback;

  /// No description provided for @serviceDetailAdditionalProductsTitle.
  ///
  /// In es, this message translates to:
  /// **'Productos adicionales'**
  String get serviceDetailAdditionalProductsTitle;

  /// No description provided for @serviceDetailProductsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los productos relacionados.'**
  String get serviceDetailProductsLoadError;

  /// No description provided for @serviceDetailProductsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos productos relacionados con este servicio.'**
  String get serviceDetailProductsEmpty;

  /// No description provided for @serviceDetailAddProductAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar producto'**
  String get serviceDetailAddProductAction;

  /// No description provided for @serviceDetailScheduleAction.
  ///
  /// In es, this message translates to:
  /// **'Agendar servicio'**
  String get serviceDetailScheduleAction;

  /// No description provided for @productDetailAvailableLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get productDetailAvailableLabel;

  /// No description provided for @productDetailAvailableUnits.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 unidad} other{{count} unidades}}'**
  String productDetailAvailableUnits(num count);

  /// No description provided for @productDetailQuantityLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get productDetailQuantityLabel;

  /// No description provided for @productDetailTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get productDetailTypeLabel;

  /// No description provided for @productDetailTypeFallback.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get productDetailTypeFallback;

  /// No description provided for @productDetailInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información del producto'**
  String get productDetailInfoTitle;

  /// No description provided for @productDetailCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get productDetailCategoryLabel;

  /// No description provided for @productDetailBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get productDetailBrandLabel;

  /// No description provided for @productDetailNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'N/D'**
  String get productDetailNotAvailable;

  /// No description provided for @productDetailDescriptionFallback.
  ///
  /// In es, this message translates to:
  /// **'Consulta los detalles de este producto directamente con el taller.'**
  String get productDetailDescriptionFallback;

  /// No description provided for @productDetailBuyAction.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get productDetailBuyAction;

  /// No description provided for @productDetailAddToCartAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar al carrito'**
  String get productDetailAddToCartAction;

  /// No description provided for @productDetailAddedToCartMessage.
  ///
  /// In es, this message translates to:
  /// **'Producto agregado al carrito.'**
  String get productDetailAddedToCartMessage;

  /// No description provided for @productDetailViewCartAction.
  ///
  /// In es, this message translates to:
  /// **'Ver carrito'**
  String get productDetailViewCartAction;

  /// No description provided for @productDetailStockLimitReached.
  ///
  /// In es, this message translates to:
  /// **'No hay más unidades disponibles de este producto.'**
  String get productDetailStockLimitReached;

  /// No description provided for @productDetailCartInvalidProduct.
  ///
  /// In es, this message translates to:
  /// **'No fue posible agregar este producto al carrito.'**
  String get productDetailCartInvalidProduct;

  /// No description provided for @productDetailCartComingSoon.
  ///
  /// In es, this message translates to:
  /// **'El carrito estará disponible próximamente.'**
  String get productDetailCartComingSoon;

  /// No description provided for @appointmentSelectServiceRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un servicio para continuar.'**
  String get appointmentSelectServiceRequired;

  /// No description provided for @appointmentSelectDateTimeRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un día y una hora.'**
  String get appointmentSelectDateTimeRequired;

  /// No description provided for @appointmentStepVehicle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar tipo de vehículo'**
  String get appointmentStepVehicle;

  /// No description provided for @appointmentStepWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Taller seleccionado'**
  String get appointmentStepWorkshop;

  /// No description provided for @appointmentStepService.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar servicio'**
  String get appointmentStepService;

  /// No description provided for @appointmentStepProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos adicionales'**
  String get appointmentStepProducts;

  /// No description provided for @appointmentStepDateTime.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar día y hora'**
  String get appointmentStepDateTime;

  /// No description provided for @appointmentStepCustomerInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del cliente'**
  String get appointmentStepCustomerInfo;

  /// No description provided for @appointmentStepConfirmation.
  ///
  /// In es, this message translates to:
  /// **'Confirmación'**
  String get appointmentStepConfirmation;

  /// No description provided for @appointmentStepPayment.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get appointmentStepPayment;

  /// No description provided for @appointmentVehicleCar.
  ///
  /// In es, this message translates to:
  /// **'AUTOMÓVIL'**
  String get appointmentVehicleCar;

  /// No description provided for @appointmentVehicleMotorcycle.
  ///
  /// In es, this message translates to:
  /// **'MOTOCICLETA / CUADRACICLO'**
  String get appointmentVehicleMotorcycle;

  /// No description provided for @appointmentVehicleLightLoad.
  ///
  /// In es, this message translates to:
  /// **'CARGA LIVIANA'**
  String get appointmentVehicleLightLoad;

  /// No description provided for @appointmentVehicleTaxi.
  ///
  /// In es, this message translates to:
  /// **'TAXI'**
  String get appointmentVehicleTaxi;

  /// No description provided for @appointmentVehicleHeavyLoad.
  ///
  /// In es, this message translates to:
  /// **'CARGA PESADA'**
  String get appointmentVehicleHeavyLoad;

  /// No description provided for @appointmentVehicleBus.
  ///
  /// In es, this message translates to:
  /// **'AUTOBÚS-MICROBÚS'**
  String get appointmentVehicleBus;

  /// No description provided for @appointmentVehicleSpecialEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipos Especiales'**
  String get appointmentVehicleSpecialEquipment;

  /// No description provided for @appointmentVehicleSpecialEquipmentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No transitan por vías públicas'**
  String get appointmentVehicleSpecialEquipmentSubtitle;

  /// No description provided for @appointmentVehicleTrailer.
  ///
  /// In es, this message translates to:
  /// **'REMOLQUE-SEMIREMOLQUE'**
  String get appointmentVehicleTrailer;

  /// No description provided for @appointmentVehiclePublicTransport.
  ///
  /// In es, this message translates to:
  /// **'AUTOBÚS-MICROBÚS TRANSPORTE PÚBLICO'**
  String get appointmentVehiclePublicTransport;

  /// No description provided for @appointmentProductsSwitchLabel.
  ///
  /// In es, this message translates to:
  /// **'Necesito productos para este servicio'**
  String get appointmentProductsSwitchLabel;

  /// No description provided for @appointmentProductsOptionalMessage.
  ///
  /// In es, this message translates to:
  /// **'Puedes continuar sin agregar productos.'**
  String get appointmentProductsOptionalMessage;

  /// No description provided for @appointmentProductsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este taller no tiene productos adicionales disponibles.'**
  String get appointmentProductsEmpty;

  /// No description provided for @appointmentProductsInvalid.
  ///
  /// In es, this message translates to:
  /// **'Uno o más productos seleccionados ya no están disponibles. Actualiza la selección e intenta nuevamente.'**
  String get appointmentProductsInvalid;

  /// No description provided for @weekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @workshopEmptySearchingNearby.
  ///
  /// In es, this message translates to:
  /// **'Buscando talleres cercanos...'**
  String get workshopEmptySearchingNearby;

  /// No description provided for @workshopEmptyEnableLocation.
  ///
  /// In es, this message translates to:
  /// **'Activa tu ubicación para ver talleres cercanos.'**
  String get workshopEmptyEnableLocation;

  /// No description provided for @workshopEmptyLocationErrorFallback.
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener tu ubicación para buscar talleres cercanos.'**
  String get workshopEmptyLocationErrorFallback;

  /// No description provided for @workshopEmptyNoNearby.
  ///
  /// In es, this message translates to:
  /// **'No encontramos talleres cercanos a tu ubicación actual.'**
  String get workshopEmptyNoNearby;

  /// No description provided for @mapPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get mapPageTitle;

  /// No description provided for @mapTopPillExplore.
  ///
  /// In es, this message translates to:
  /// **'Explora talleres'**
  String get mapTopPillExplore;

  /// No description provided for @mapTopPillLoadingWorkshops.
  ///
  /// In es, this message translates to:
  /// **'Cargando talleres'**
  String get mapTopPillLoadingWorkshops;

  /// No description provided for @mapTopPillNoWorkshops.
  ///
  /// In es, this message translates to:
  /// **'Sin talleres'**
  String get mapTopPillNoWorkshops;

  /// No description provided for @mapSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en Autolab'**
  String get mapSearchHint;

  /// No description provided for @mapSearchFiltersTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get mapSearchFiltersTooltip;

  /// No description provided for @mapSearchClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get mapSearchClearTooltip;

  /// No description provided for @mapFilterOffers.
  ///
  /// In es, this message translates to:
  /// **'Ofertas'**
  String get mapFilterOffers;

  /// No description provided for @mapFilterService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get mapFilterService;

  /// No description provided for @mapFilterTopRated.
  ///
  /// In es, this message translates to:
  /// **'Mejor calificado'**
  String get mapFilterTopRated;

  /// No description provided for @mapLoadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargando mapa'**
  String get mapLoadingTitle;

  /// No description provided for @mapLoadingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando el mapa y los talleres disponibles para ti.'**
  String get mapLoadingMessage;

  /// No description provided for @mapLoadingTimeoutTitle.
  ///
  /// In es, this message translates to:
  /// **'El mapa está tardando en responder'**
  String get mapLoadingTimeoutTitle;

  /// No description provided for @mapLoadingTimeoutMessage.
  ///
  /// In es, this message translates to:
  /// **'Los talleres ya están disponibles. Si el mapa no aparece, revisa la conexión, permisos de ubicación o la configuración de Google Maps del dispositivo.'**
  String get mapLoadingTimeoutMessage;

  /// No description provided for @mapAttributionOpenStreetMap.
  ///
  /// In es, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get mapAttributionOpenStreetMap;

  /// No description provided for @mapWorkshopsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los talleres en este momento.'**
  String get mapWorkshopsLoadError;

  /// No description provided for @mapWorkshopsNetworkError.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión para consultar los talleres cercanos.'**
  String get mapWorkshopsNetworkError;

  /// No description provided for @mapErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el mapa'**
  String get mapErrorTitle;

  /// No description provided for @mapErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo nuevamente. Los talleres seguirán disponibles cuando el mapa se recupere.'**
  String get mapErrorMessage;

  /// No description provided for @mapRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get mapRetry;

  /// No description provided for @mapYourLocation.
  ///
  /// In es, this message translates to:
  /// **'Tu ubicación'**
  String get mapYourLocation;

  /// No description provided for @mapZoomInTooltip.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get mapZoomInTooltip;

  /// No description provided for @mapZoomOutTooltip.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get mapZoomOutTooltip;

  /// No description provided for @mapInfoDistancePrefix.
  ///
  /// In es, this message translates to:
  /// **'A {distance}'**
  String mapInfoDistancePrefix(Object distance);

  /// No description provided for @mapInfoCoveragePrefix.
  ///
  /// In es, this message translates to:
  /// **'Cobertura {distance}'**
  String mapInfoCoveragePrefix(Object distance);

  /// No description provided for @mapSheetFallbackAddress.
  ///
  /// In es, this message translates to:
  /// **'Ubicación disponible en el mapa.'**
  String get mapSheetFallbackAddress;

  /// No description provided for @mapSheetLabelWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Taller'**
  String get mapSheetLabelWorkshop;

  /// No description provided for @mapSheetLabelCoverage.
  ///
  /// In es, this message translates to:
  /// **'Alcance'**
  String get mapSheetLabelCoverage;

  /// No description provided for @mapSheetFallbackDescription.
  ///
  /// In es, this message translates to:
  /// **'Este taller está listo para atender solicitudes cerca de tu ubicación.'**
  String get mapSheetFallbackDescription;

  /// No description provided for @mapSheetNearbyWorkshopsTitle.
  ///
  /// In es, this message translates to:
  /// **'Talleres en esta zona'**
  String get mapSheetNearbyWorkshopsTitle;

  /// No description provided for @mapSheetOneResult.
  ///
  /// In es, this message translates to:
  /// **'1 resultado'**
  String get mapSheetOneResult;

  /// No description provided for @mapSheetResults.
  ///
  /// In es, this message translates to:
  /// **'{count} resultados'**
  String mapSheetResults(Object count);

  /// No description provided for @mapSheetNoSearchResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos talleres para esa búsqueda.'**
  String get mapSheetNoSearchResults;

  /// No description provided for @mapSheetProductsLabel.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get mapSheetProductsLabel;

  /// No description provided for @mapSheetViewOnMapTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver en mapa'**
  String get mapSheetViewOnMapTooltip;

  /// No description provided for @mapSheetOpenWorkshopAction.
  ///
  /// In es, this message translates to:
  /// **'Ver taller'**
  String get mapSheetOpenWorkshopAction;

  /// No description provided for @mapSheetProductSearchResults.
  ///
  /// In es, this message translates to:
  /// **'{count} resultados para \"{query}\"'**
  String mapSheetProductSearchResults(Object count, Object query);

  /// No description provided for @mapMarkerTooltipWithAddress.
  ///
  /// In es, this message translates to:
  /// **'{name}\n{address}'**
  String mapMarkerTooltipWithAddress(Object name, Object address);

  /// No description provided for @mapMarkerTooltipWithoutAddress.
  ///
  /// In es, this message translates to:
  /// **'{name}'**
  String mapMarkerTooltipWithoutAddress(Object name);

  /// No description provided for @homePlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Explora talleres cerca de ti'**
  String get homePlaceholderTitle;

  /// No description provided for @homePlaceholderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Este espacio queda libre para integrar carruseles, listados y resultados dinámicos sin mezclar contenido demo dentro del home.'**
  String get homePlaceholderSubtitle;

  /// No description provided for @homeNeedsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas hoy?'**
  String get homeNeedsTitle;

  /// No description provided for @homeServiceBalance.
  ///
  /// In es, this message translates to:
  /// **'Balanceo'**
  String get homeServiceBalance;

  /// No description provided for @homeServiceTow.
  ///
  /// In es, this message translates to:
  /// **'Grúa'**
  String get homeServiceTow;

  /// No description provided for @homeServiceTires.
  ///
  /// In es, this message translates to:
  /// **'Llantas'**
  String get homeServiceTires;

  /// No description provided for @homeServiceGeneralReview.
  ///
  /// In es, this message translates to:
  /// **'Revisión\ngeneral'**
  String get homeServiceGeneralReview;

  /// No description provided for @homeServiceElectricMechanic.
  ///
  /// In es, this message translates to:
  /// **'Mecánica\neléctrica'**
  String get homeServiceElectricMechanic;

  /// No description provided for @homeServiceBattery.
  ///
  /// In es, this message translates to:
  /// **'Batería'**
  String get homeServiceBattery;

  /// No description provided for @homePromotionsComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get homePromotionsComingSoon;

  /// No description provided for @homePromotionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Promociones y beneficios'**
  String get homePromotionsTitle;

  /// No description provided for @homePromotionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Muy pronto estarán disponibles para ti.'**
  String get homePromotionsSubtitle;

  /// No description provided for @appointmentCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cita fue creada correctamente.'**
  String get appointmentCreatedSuccess;

  /// No description provided for @appointmentCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear la cita. Inténtalo nuevamente.'**
  String get appointmentCreateFailed;

  /// No description provided for @appointmentVehicleValidationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar el vehículo.'**
  String get appointmentVehicleValidationFailed;

  /// No description provided for @appointmentScheduleValidationFailedShort.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar el horario.'**
  String get appointmentScheduleValidationFailedShort;

  /// No description provided for @appointmentDateUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Ese día ya no tiene horarios disponibles. Selecciona otra fecha.'**
  String get appointmentDateUnavailable;

  /// No description provided for @appointmentScheduleRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona fecha y hora para continuar.'**
  String get appointmentScheduleRequired;

  /// No description provided for @appointmentSlotUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Ese horario acaba de ocuparse. Selecciona otra hora.'**
  String get appointmentSlotUnavailable;

  /// No description provided for @appointmentScheduleValidationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar el horario. Inténtalo nuevamente.'**
  String get appointmentScheduleValidationFailed;

  /// No description provided for @appointmentVehiclePlateRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un vehículo para continuar.'**
  String get appointmentVehiclePlateRequired;

  /// No description provided for @appointmentVehiclePlateConflict.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes un vehículo con esta placa. Selecciónalo de la lista o edítalo desde Gestionar vehículos.'**
  String get appointmentVehiclePlateConflict;

  /// No description provided for @appointmentVehicleValidationFailedDetailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar el vehículo. Revisa la información e inténtalo de nuevo.'**
  String get appointmentVehicleValidationFailedDetailed;

  /// No description provided for @appointmentBookingIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Revisa que el vehículo, servicio, fecha y hora estén completos.'**
  String get appointmentBookingIncomplete;

  /// No description provided for @appointmentAuthRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para poder reservar tu cita.'**
  String get appointmentAuthRequired;

  /// No description provided for @appointmentDateTimeInPast.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una fecha y hora disponible más adelante.'**
  String get appointmentDateTimeInPast;

  /// No description provided for @appointmentInvalidSlotInterval.
  ///
  /// In es, this message translates to:
  /// **'Selecciona uno de los horarios disponibles.'**
  String get appointmentInvalidSlotInterval;

  /// No description provided for @appointmentBusinessHoursUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este taller aún no tiene horario configurado para ese día.'**
  String get appointmentBusinessHoursUnavailable;

  /// No description provided for @appointmentWorkshopClosed.
  ///
  /// In es, this message translates to:
  /// **'El taller está cerrado ese día. Selecciona otra fecha.'**
  String get appointmentWorkshopClosed;

  /// No description provided for @appointmentOutsideBusinessHours.
  ///
  /// In es, this message translates to:
  /// **'Ese horario está fuera del horario de atención del taller.'**
  String get appointmentOutsideBusinessHours;

  /// No description provided for @appointmentServiceNotSchedulable.
  ///
  /// In es, this message translates to:
  /// **'Este servicio ya no está disponible para agendar.'**
  String get appointmentServiceNotSchedulable;

  /// No description provided for @appointmentServiceDurationRequired.
  ///
  /// In es, this message translates to:
  /// **'Este servicio no tiene duración configurada. Contacta al taller para poder agendarlo.'**
  String get appointmentServiceDurationRequired;

  /// No description provided for @appointmentNoActiveEmployees.
  ///
  /// In es, this message translates to:
  /// **'Este taller no tiene empleados activos disponibles para recibir citas.'**
  String get appointmentNoActiveEmployees;

  /// No description provided for @appointmentVehicleNotOwned.
  ///
  /// In es, this message translates to:
  /// **'No pudimos usar ese vehículo con tu usuario.'**
  String get appointmentVehicleNotOwned;

  /// No description provided for @appointmentVehiclePlateRequiredForBooking.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la placa del vehículo para reservar.'**
  String get appointmentVehiclePlateRequiredForBooking;

  /// No description provided for @appointmentBookingConfigurationFailed.
  ///
  /// In es, this message translates to:
  /// **'La reserva no está configurada correctamente. Contacta al equipo de soporte.'**
  String get appointmentBookingConfigurationFailed;

  /// No description provided for @appointmentStepVehicleInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del vehículo'**
  String get appointmentStepVehicleInfo;

  /// No description provided for @appointmentWorkshopFallbackDescription.
  ///
  /// In es, this message translates to:
  /// **'Servicio y mantenimiento automotriz'**
  String get appointmentWorkshopFallbackDescription;

  /// No description provided for @appointmentVehiclePlateLabel.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get appointmentVehiclePlateLabel;

  /// No description provided for @appointmentVehiclePlateHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. ABC123'**
  String get appointmentVehiclePlateHint;

  /// No description provided for @appointmentVehicleTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get appointmentVehicleTypeLabel;

  /// No description provided for @appointmentVehicleTypeCar.
  ///
  /// In es, this message translates to:
  /// **'Automóvil'**
  String get appointmentVehicleTypeCar;

  /// No description provided for @appointmentVehicleTypeMotorcycle.
  ///
  /// In es, this message translates to:
  /// **'Motocicleta'**
  String get appointmentVehicleTypeMotorcycle;

  /// No description provided for @appointmentVehicleTypePickup.
  ///
  /// In es, this message translates to:
  /// **'Pickup'**
  String get appointmentVehicleTypePickup;

  /// No description provided for @appointmentVehicleTypeSuv.
  ///
  /// In es, this message translates to:
  /// **'SUV'**
  String get appointmentVehicleTypeSuv;

  /// No description provided for @appointmentVehicleTypeTruck.
  ///
  /// In es, this message translates to:
  /// **'Camión'**
  String get appointmentVehicleTypeTruck;

  /// No description provided for @appointmentVehicleTypeBus.
  ///
  /// In es, this message translates to:
  /// **'Bus'**
  String get appointmentVehicleTypeBus;

  /// No description provided for @appointmentVehicleTypeTrailer.
  ///
  /// In es, this message translates to:
  /// **'Remolque'**
  String get appointmentVehicleTypeTrailer;

  /// No description provided for @appointmentVehicleTypeSpecialEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo especial'**
  String get appointmentVehicleTypeSpecialEquipment;

  /// No description provided for @appointmentVehicleBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get appointmentVehicleBrandLabel;

  /// No description provided for @appointmentVehicleBrandHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Toyota'**
  String get appointmentVehicleBrandHint;

  /// No description provided for @appointmentVehicleModelLabel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get appointmentVehicleModelLabel;

  /// No description provided for @appointmentVehicleModelHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Yaris'**
  String get appointmentVehicleModelHint;

  /// No description provided for @appointmentVehicleYearLabel.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get appointmentVehicleYearLabel;

  /// No description provided for @appointmentVehicleYearHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 2019'**
  String get appointmentVehicleYearHint;

  /// No description provided for @appointmentVehicleColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get appointmentVehicleColorLabel;

  /// No description provided for @appointmentVehicleColorHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Negro'**
  String get appointmentVehicleColorHint;

  /// No description provided for @appointmentVehicleFuelLabel.
  ///
  /// In es, this message translates to:
  /// **'Combustible'**
  String get appointmentVehicleFuelLabel;

  /// No description provided for @appointmentVehicleFuelGasoline.
  ///
  /// In es, this message translates to:
  /// **'Gasolina'**
  String get appointmentVehicleFuelGasoline;

  /// No description provided for @appointmentVehicleFuelDiesel.
  ///
  /// In es, this message translates to:
  /// **'Diésel'**
  String get appointmentVehicleFuelDiesel;

  /// No description provided for @appointmentVehicleFuelElectric.
  ///
  /// In es, this message translates to:
  /// **'Eléctrico'**
  String get appointmentVehicleFuelElectric;

  /// No description provided for @appointmentVehicleFuelHybrid.
  ///
  /// In es, this message translates to:
  /// **'Híbrido'**
  String get appointmentVehicleFuelHybrid;

  /// No description provided for @appointmentVehicleTransmissionLabel.
  ///
  /// In es, this message translates to:
  /// **'Transmisión'**
  String get appointmentVehicleTransmissionLabel;

  /// No description provided for @appointmentVehicleTransmissionManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get appointmentVehicleTransmissionManual;

  /// No description provided for @appointmentVehicleTransmissionAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automática'**
  String get appointmentVehicleTransmissionAutomatic;

  /// No description provided for @appointmentMyVehiclesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis vehículos'**
  String get appointmentMyVehiclesTitle;

  /// No description provided for @appointmentAddVehicleShortAction.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get appointmentAddVehicleShortAction;

  /// No description provided for @appointmentNewVehicleAction.
  ///
  /// In es, this message translates to:
  /// **'+ Nuevo'**
  String get appointmentNewVehicleAction;

  /// No description provided for @appointmentNoVehiclesForWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes vehículos guardados.'**
  String get appointmentNoVehiclesForWorkshop;

  /// No description provided for @appointmentNoSchedulableServices.
  ///
  /// In es, this message translates to:
  /// **'Este taller no tiene servicios disponibles para agendar.'**
  String get appointmentNoSchedulableServices;

  /// No description provided for @appointmentBackAction.
  ///
  /// In es, this message translates to:
  /// **'ANTERIOR'**
  String get appointmentBackAction;

  /// No description provided for @appointmentExitAction.
  ///
  /// In es, this message translates to:
  /// **'SALIR'**
  String get appointmentExitAction;

  /// No description provided for @appointmentNewServiceAction.
  ///
  /// In es, this message translates to:
  /// **'NUEVO SERVICIO'**
  String get appointmentNewServiceAction;

  /// No description provided for @appointmentCreatingAction.
  ///
  /// In es, this message translates to:
  /// **'CREANDO'**
  String get appointmentCreatingAction;

  /// No description provided for @appointmentCreatingTitle.
  ///
  /// In es, this message translates to:
  /// **'Creando cita'**
  String get appointmentCreatingTitle;

  /// No description provided for @appointmentCreatingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos confirmando tu reserva. No cierres esta pantalla.'**
  String get appointmentCreatingMessage;

  /// No description provided for @appointmentOpeningPaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando pago seguro'**
  String get appointmentOpeningPaymentTitle;

  /// No description provided for @appointmentOpeningPaymentMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos abriendo la pasarela de pago. No cierres la app.'**
  String get appointmentOpeningPaymentMessage;

  /// No description provided for @appointmentConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR CITA'**
  String get appointmentConfirmAction;

  /// No description provided for @appointmentFinishAction.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR'**
  String get appointmentFinishAction;

  /// No description provided for @appointmentPayAction.
  ///
  /// In es, this message translates to:
  /// **'PAGAR'**
  String get appointmentPayAction;

  /// No description provided for @appointmentNextAction.
  ///
  /// In es, this message translates to:
  /// **'SIGUIENTE'**
  String get appointmentNextAction;

  /// No description provided for @appointmentSelectedDayLegend.
  ///
  /// In es, this message translates to:
  /// **'Día seleccionado'**
  String get appointmentSelectedDayLegend;

  /// No description provided for @appointmentAvailableDayLegend.
  ///
  /// In es, this message translates to:
  /// **'Día disponible'**
  String get appointmentAvailableDayLegend;

  /// No description provided for @appointmentOccupiedDayLegend.
  ///
  /// In es, this message translates to:
  /// **'Día ocupado'**
  String get appointmentOccupiedDayLegend;

  /// No description provided for @appointmentAvailableHoursTitle.
  ///
  /// In es, this message translates to:
  /// **'Horas disponibles'**
  String get appointmentAvailableHoursTitle;

  /// No description provided for @appointmentPickupLabel.
  ///
  /// In es, this message translates to:
  /// **'PICK UP:'**
  String get appointmentPickupLabel;

  /// No description provided for @appointmentAvailableHoursLoading.
  ///
  /// In es, this message translates to:
  /// **'Estamos consultando los horarios disponibles.'**
  String get appointmentAvailableHoursLoading;

  /// No description provided for @appointmentAvailableHoursFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar la disponibilidad. Inténtalo nuevamente.'**
  String get appointmentAvailableHoursFailed;

  /// No description provided for @appointmentAvailableHoursEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay horarios disponibles para este día.'**
  String get appointmentAvailableHoursEmpty;

  /// No description provided for @appointmentMonthYearTitle.
  ///
  /// In es, this message translates to:
  /// **'{month} de {year}'**
  String appointmentMonthYearTitle(Object month, Object year);

  /// No description provided for @appointmentFullDate.
  ///
  /// In es, this message translates to:
  /// **'{day} de {month} {year}'**
  String appointmentFullDate(Object day, Object month, Object year);

  /// No description provided for @appointmentPendingDate.
  ///
  /// In es, this message translates to:
  /// **'fecha pendiente'**
  String get appointmentPendingDate;

  /// No description provided for @appointmentConfirmationReadyTitle.
  ///
  /// In es, this message translates to:
  /// **'Cita lista para confirmar'**
  String get appointmentConfirmationReadyTitle;

  /// No description provided for @appointmentPendingPlate.
  ///
  /// In es, this message translates to:
  /// **'Placa pendiente'**
  String get appointmentPendingPlate;

  /// No description provided for @appointmentServiceLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get appointmentServiceLabel;

  /// No description provided for @appointmentServicePaidAtWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Se paga en taller'**
  String get appointmentServicePaidAtWorkshop;

  /// No description provided for @appointmentPendingService.
  ///
  /// In es, this message translates to:
  /// **'Servicio pendiente'**
  String get appointmentPendingService;

  /// No description provided for @appointmentDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get appointmentDateLabel;

  /// No description provided for @appointmentConfirmationDeliveryMessage.
  ///
  /// In es, this message translates to:
  /// **'Recibirás los detalles por correo o WhatsApp.'**
  String get appointmentConfirmationDeliveryMessage;

  /// No description provided for @appointmentWorkshopLabel.
  ///
  /// In es, this message translates to:
  /// **'Taller'**
  String get appointmentWorkshopLabel;

  /// No description provided for @appointmentDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get appointmentDurationLabel;

  /// No description provided for @appointmentPaymentMethodLabel.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get appointmentPaymentMethodLabel;

  /// No description provided for @laropayPaymentResultPaidTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago confirmado'**
  String get laropayPaymentResultPaidTitle;

  /// No description provided for @laropayPaymentResultPaidMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu orden fue aprobada correctamente. Ya puedes revisar el detalle en Mis órdenes.'**
  String get laropayPaymentResultPaidMessage;

  /// No description provided for @laropayPaymentResultRejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago no procesado'**
  String get laropayPaymentResultRejectedTitle;

  /// No description provided for @laropayPaymentResultRejectedMessage.
  ///
  /// In es, this message translates to:
  /// **'Laropay no pudo procesar el pago. Puedes revisar el estado o intentar nuevamente desde Mis órdenes.'**
  String get laropayPaymentResultRejectedMessage;

  /// No description provided for @laropayPaymentResultExpiredTitle.
  ///
  /// In es, this message translates to:
  /// **'Link vencido'**
  String get laropayPaymentResultExpiredTitle;

  /// No description provided for @laropayPaymentResultExpiredMessage.
  ///
  /// In es, this message translates to:
  /// **'El link de pago ya no está disponible. Genera una nueva orden para continuar.'**
  String get laropayPaymentResultExpiredMessage;

  /// No description provided for @laropayPaymentResultPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago en revisión'**
  String get laropayPaymentResultPendingTitle;

  /// No description provided for @laropayPaymentResultPendingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos esperando la confirmación de Laropay. Puedes actualizar el estado desde Mis órdenes.'**
  String get laropayPaymentResultPendingMessage;

  /// No description provided for @laropayPaymentResultViewPurchasesAction.
  ///
  /// In es, this message translates to:
  /// **'Ver mis órdenes'**
  String get laropayPaymentResultViewPurchasesAction;

  /// No description provided for @laropayPaymentResultBackToWorkshopAction.
  ///
  /// In es, this message translates to:
  /// **'Volver al taller'**
  String get laropayPaymentResultBackToWorkshopAction;

  /// No description provided for @laropayPaymentStartError.
  ///
  /// In es, this message translates to:
  /// **'La cita fue creada, pero no fue posible abrir el pago de Laropay. Revisa el estado de tu cita más tarde.'**
  String get laropayPaymentStartError;

  /// No description provided for @laropayPaymentStartErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No fue posible abrir Laropay'**
  String get laropayPaymentStartErrorTitle;

  /// No description provided for @laropayRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get laropayRetryAction;

  /// No description provided for @laropayCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get laropayCancelAction;

  /// No description provided for @appointmentCustomerNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get appointmentCustomerNameLabel;

  /// No description provided for @appointmentCustomerPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono de contacto'**
  String get appointmentCustomerPhoneLabel;

  /// No description provided for @appointmentCustomerEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo para la cita'**
  String get appointmentCustomerEmailLabel;

  /// No description provided for @appointmentCustomerIdentificationLabel.
  ///
  /// In es, this message translates to:
  /// **'Cédula'**
  String get appointmentCustomerIdentificationLabel;

  /// No description provided for @appointmentCustomerFiscalIdTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de identificación'**
  String get appointmentCustomerFiscalIdTypeLabel;

  /// No description provided for @appointmentOptionalNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota opcional'**
  String get appointmentOptionalNoteLabel;

  /// No description provided for @appointmentNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get appointmentNoteHint;

  /// No description provided for @appointmentOptionalNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega detalles importantes para el taller.'**
  String get appointmentOptionalNoteHint;

  /// No description provided for @appointmentProductsLabel.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get appointmentProductsLabel;

  /// No description provided for @appointmentNoAdditionalProducts.
  ///
  /// In es, this message translates to:
  /// **'Sin productos adicionales.'**
  String get appointmentNoAdditionalProducts;

  /// No description provided for @appointmentCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Costo'**
  String get appointmentCostLabel;

  /// No description provided for @appointmentSubtotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get appointmentSubtotalLabel;

  /// No description provided for @appointmentTaxLabel.
  ///
  /// In es, this message translates to:
  /// **'IVA'**
  String get appointmentTaxLabel;

  /// No description provided for @appointmentTotalToPayLabel.
  ///
  /// In es, this message translates to:
  /// **'Total a pagar'**
  String get appointmentTotalToPayLabel;

  /// No description provided for @appointmentPriceWithTaxSuffix.
  ///
  /// In es, this message translates to:
  /// **'{price} IVA'**
  String appointmentPriceWithTaxSuffix(Object price);

  /// No description provided for @appointmentPriceToConfirm.
  ///
  /// In es, this message translates to:
  /// **'Por confirmar'**
  String get appointmentPriceToConfirm;

  /// No description provided for @cartTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi carrito'**
  String get cartTitle;

  /// No description provided for @cartCartsTitle.
  ///
  /// In es, this message translates to:
  /// **'Carritos'**
  String get cartCartsTitle;

  /// No description provided for @cartCheckoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get cartCheckoutTitle;

  /// No description provided for @cartProductCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin productos} =1{1 producto} other{{count} productos}}'**
  String cartProductCount(num count);

  /// No description provided for @cartStockLimitReached.
  ///
  /// In es, this message translates to:
  /// **'No hay más unidades disponibles de este producto.'**
  String get cartStockLimitReached;

  /// No description provided for @cartFreeShippingBanner.
  ///
  /// In es, this message translates to:
  /// **'Envío gratis en compras mayores a ₡25.000'**
  String get cartFreeShippingBanner;

  /// No description provided for @cartAdditionalProducts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 producto adicional} other{{count} productos adicionales}}'**
  String cartAdditionalProducts(num count);

  /// No description provided for @cartDeliveryServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio de envío'**
  String get cartDeliveryServiceTitle;

  /// No description provided for @cartDeliveryAddressDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de dirección de envío'**
  String get cartDeliveryAddressDetails;

  /// No description provided for @cartDeliveryDisabledMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas envío?'**
  String get cartDeliveryDisabledMessage;

  /// No description provided for @cartSavedAddressesTitle.
  ///
  /// In es, this message translates to:
  /// **'Direcciones guardadas'**
  String get cartSavedAddressesTitle;

  /// No description provided for @cartNewAddressAction.
  ///
  /// In es, this message translates to:
  /// **'Nueva dirección'**
  String get cartNewAddressAction;

  /// No description provided for @cartAddressHint.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get cartAddressHint;

  /// No description provided for @cartAddressRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una dirección para continuar.'**
  String get cartAddressRequired;

  /// No description provided for @cartAddAddressAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get cartAddAddressAction;

  /// No description provided for @cartEditAddressAction.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get cartEditAddressAction;

  /// No description provided for @cartDeliveryFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Dirección de entrega'**
  String get cartDeliveryFormTitle;

  /// No description provided for @cartProvinceLabel.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get cartProvinceLabel;

  /// No description provided for @cartCantonLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantón'**
  String get cartCantonLabel;

  /// No description provided for @cartDistrictLabel.
  ///
  /// In es, this message translates to:
  /// **'Distrito'**
  String get cartDistrictLabel;

  /// No description provided for @cartExactAddressLabel.
  ///
  /// In es, this message translates to:
  /// **'Ubicación exacta'**
  String get cartExactAddressLabel;

  /// No description provided for @cartPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de celular'**
  String get cartPhoneLabel;

  /// No description provided for @cartPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número de teléfono válido.'**
  String get cartPhoneInvalid;

  /// No description provided for @cartSaveAddressAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar dirección'**
  String get cartSaveAddressAction;

  /// No description provided for @cartSavingAddressAction.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get cartSavingAddressAction;

  /// No description provided for @cartSaveAddressError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible guardar la dirección. Intenta nuevamente.'**
  String get cartSaveAddressError;

  /// No description provided for @cartDeleteAddressSuccess.
  ///
  /// In es, this message translates to:
  /// **'Dirección eliminada correctamente.'**
  String get cartDeleteAddressSuccess;

  /// No description provided for @cartDeleteAddressError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible eliminar la dirección. Intenta nuevamente.'**
  String get cartDeleteAddressError;

  /// No description provided for @cartDeleteAddressTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar dirección'**
  String get cartDeleteAddressTitle;

  /// No description provided for @cartDeleteAddressMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar esta dirección?'**
  String get cartDeleteAddressMessage;

  /// No description provided for @cartDeleteAddressCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cartDeleteAddressCancel;

  /// No description provided for @cartDeleteAddressConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get cartDeleteAddressConfirm;

  /// No description provided for @cartFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get cartFieldRequired;

  /// No description provided for @cartSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get cartSummaryTitle;

  /// No description provided for @cartSubtotal.
  ///
  /// In es, this message translates to:
  /// **'Subtotal ({count, plural, =1{1 producto} other{{count} productos}})'**
  String cartSubtotal(num count);

  /// No description provided for @cartShipping.
  ///
  /// In es, this message translates to:
  /// **'Envío'**
  String get cartShipping;

  /// No description provided for @cartFreeShipping.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get cartFreeShipping;

  /// No description provided for @cartTaxes.
  ///
  /// In es, this message translates to:
  /// **'IVA incluido'**
  String get cartTaxes;

  /// No description provided for @cartTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @cartFinishPurchase.
  ///
  /// In es, this message translates to:
  /// **'Finalizar compra'**
  String get cartFinishPurchase;

  /// No description provided for @cartContinueToCheckout.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get cartContinueToCheckout;

  /// No description provided for @cartViewCartAction.
  ///
  /// In es, this message translates to:
  /// **'Ver carrito'**
  String get cartViewCartAction;

  /// No description provided for @cartViewWorkshopAction.
  ///
  /// In es, this message translates to:
  /// **'Ver taller'**
  String get cartViewWorkshopAction;

  /// No description provided for @cartPurchaseComingSoon.
  ///
  /// In es, this message translates to:
  /// **'La compra estará disponible próximamente.'**
  String get cartPurchaseComingSoon;

  /// No description provided for @cartCreatingOrder.
  ///
  /// In es, this message translates to:
  /// **'Creando orden...'**
  String get cartCreatingOrder;

  /// No description provided for @cartCreatingOrderMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos validando tu carrito.'**
  String get cartCreatingOrderMessage;

  /// No description provided for @cartOpeningLaropayTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando pago seguro'**
  String get cartOpeningLaropayTitle;

  /// No description provided for @cartOpeningLaropayMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos abriendo la pasarela de pago. No cierres la app.'**
  String get cartOpeningLaropayMessage;

  /// No description provided for @cartCreateOrderSuccess.
  ///
  /// In es, this message translates to:
  /// **'Orden {orderNumber} creada correctamente.'**
  String cartCreateOrderSuccess(Object orderNumber);

  /// No description provided for @cartOrderSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Compra exitosa!'**
  String get cartOrderSuccessTitle;

  /// No description provided for @cartOrderSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido fue creado correctamente.'**
  String get cartOrderSuccessMessage;

  /// No description provided for @cartOrderNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Orden'**
  String get cartOrderNumberLabel;

  /// No description provided for @cartOrderSuccessAction.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get cartOrderSuccessAction;

  /// No description provided for @cartPaymentReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Pago en revisión'**
  String get cartPaymentReviewTitle;

  /// No description provided for @cartPaymentReviewMessage.
  ///
  /// In es, this message translates to:
  /// **'La orden fue creada, pero no fue posible procesar el pago. Revisa el estado de la orden y paga en el taller.'**
  String get cartPaymentReviewMessage;

  /// No description provided for @cartPaymentReviewAction.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get cartPaymentReviewAction;

  /// No description provided for @cartCreateOrderError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible crear la orden. Intenta nuevamente.'**
  String get cartCreateOrderError;

  /// No description provided for @cartSecurePurchaseTitle.
  ///
  /// In es, this message translates to:
  /// **'Compra segura'**
  String get cartSecurePurchaseTitle;

  /// No description provided for @cartSecurePurchaseMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están protegidos'**
  String get cartSecurePurchaseMessage;

  /// No description provided for @cartNeedHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas ayuda?'**
  String get cartNeedHelpTitle;

  /// No description provided for @cartNeedHelpMessage.
  ///
  /// In es, this message translates to:
  /// **'Contáctanos'**
  String get cartNeedHelpMessage;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu carrito está vacío'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Agrega productos desde un taller para verlos aquí.'**
  String get cartEmptyMessage;

  /// No description provided for @appointmentDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String appointmentDurationMinutes(Object minutes);

  /// No description provided for @appointmentDurationHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String appointmentDurationHours(Object hours);

  /// No description provided for @appointmentDurationHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String appointmentDurationHoursMinutes(Object hours, Object minutes);

  /// No description provided for @myPurchasesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis órdenes'**
  String get myPurchasesTitle;

  /// No description provided for @myPurchasesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta tus órdenes y pagos'**
  String get myPurchasesSubtitle;

  /// No description provided for @myPurchasesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes órdenes'**
  String get myPurchasesEmptyTitle;

  /// No description provided for @myPurchasesEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando agendes una cita o generes una compra, aparecerá aquí con su estado.'**
  String get myPurchasesEmptyMessage;

  /// No description provided for @myPurchasesLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus órdenes'**
  String get myPurchasesLoadErrorTitle;

  /// No description provided for @myPurchasesRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get myPurchasesRetryAction;

  /// No description provided for @myPurchasesPendingStatus.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get myPurchasesPendingStatus;

  /// No description provided for @myPurchasesPartialStatus.
  ///
  /// In es, this message translates to:
  /// **'Pago parcial'**
  String get myPurchasesPartialStatus;

  /// No description provided for @myPurchasesApprovedStatus.
  ///
  /// In es, this message translates to:
  /// **'Procesado'**
  String get myPurchasesApprovedStatus;

  /// No description provided for @myPurchasesRejectedStatus.
  ///
  /// In es, this message translates to:
  /// **'No procesado'**
  String get myPurchasesRejectedStatus;

  /// No description provided for @myPurchasesExpiredStatus.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get myPurchasesExpiredStatus;

  /// No description provided for @myPurchasesWorkshopPaymentStatus.
  ///
  /// In es, this message translates to:
  /// **'Pago en taller'**
  String get myPurchasesWorkshopPaymentStatus;

  /// No description provided for @myPurchasesUnknownStatus.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get myPurchasesUnknownStatus;

  /// No description provided for @myPurchasesPendingMessage.
  ///
  /// In es, this message translates to:
  /// **'El link fue generado. Esperamos la confirmación de Laropay.'**
  String get myPurchasesPendingMessage;

  /// No description provided for @myPurchasesPartialMessage.
  ///
  /// In es, this message translates to:
  /// **'Productos pagados. Servicio pendiente de pago en el taller.'**
  String get myPurchasesPartialMessage;

  /// No description provided for @myPurchasesApprovedMessage.
  ///
  /// In es, this message translates to:
  /// **'El pago fue confirmado correctamente.'**
  String get myPurchasesApprovedMessage;

  /// No description provided for @myPurchasesRejectedMessage.
  ///
  /// In es, this message translates to:
  /// **'El pago no pudo ser procesado.'**
  String get myPurchasesRejectedMessage;

  /// No description provided for @myPurchasesExpiredMessage.
  ///
  /// In es, this message translates to:
  /// **'El link de pago venció o ya no está disponible.'**
  String get myPurchasesExpiredMessage;

  /// No description provided for @myPurchasesWorkshopPaymentMessage.
  ///
  /// In es, this message translates to:
  /// **'Servicio agendado. El pago se realiza directamente en el taller.'**
  String get myPurchasesWorkshopPaymentMessage;

  /// No description provided for @myPurchasesUnknownMessage.
  ///
  /// In es, this message translates to:
  /// **'El pago está en revisión.'**
  String get myPurchasesUnknownMessage;

  /// No description provided for @myPurchasesDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Compra de productos'**
  String get myPurchasesDefaultTitle;

  /// No description provided for @myPurchasesUnknownValue.
  ///
  /// In es, this message translates to:
  /// **'N/D'**
  String get myPurchasesUnknownValue;

  /// No description provided for @myPurchasesAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get myPurchasesAmountLabel;

  /// No description provided for @myPurchasesPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get myPurchasesPaidLabel;

  /// No description provided for @myPurchasesPaidOnlineLabel.
  ///
  /// In es, this message translates to:
  /// **'Pagado en línea'**
  String get myPurchasesPaidOnlineLabel;

  /// No description provided for @myPurchasesPendingAtWorkshopLabel.
  ///
  /// In es, this message translates to:
  /// **'Pendiente en taller'**
  String get myPurchasesPendingAtWorkshopLabel;

  /// No description provided for @myPurchasesOrderTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total de la orden'**
  String get myPurchasesOrderTotalLabel;

  /// No description provided for @myPurchasesDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get myPurchasesDateLabel;

  /// No description provided for @myPurchasesReferenceLabel.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get myPurchasesReferenceLabel;

  /// No description provided for @myPurchasesOpenLinkAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar pago'**
  String get myPurchasesOpenLinkAction;

  /// No description provided for @myPurchasesRefreshStatusAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar estado'**
  String get myPurchasesRefreshStatusAction;

  /// No description provided for @myPurchasesRefreshingReturnedPayment.
  ///
  /// In es, this message translates to:
  /// **'Estamos confirmando tu pago con Laropay.'**
  String get myPurchasesRefreshingReturnedPayment;

  /// No description provided for @myPurchasesStatusRefreshSuccess.
  ///
  /// In es, this message translates to:
  /// **'Estado de pago actualizado.'**
  String get myPurchasesStatusRefreshSuccess;

  /// No description provided for @myPurchasesStatusRefreshError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible actualizar el estado del pago.'**
  String get myPurchasesStatusRefreshError;

  /// No description provided for @myPurchasesLinkOpenError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible abrir el link de pago.'**
  String get myPurchasesLinkOpenError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
