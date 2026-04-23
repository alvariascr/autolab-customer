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

  /// No description provided for @navigationProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navigationProfile;

  /// No description provided for @searchBarHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar talleres...'**
  String get searchBarHint;

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

  /// No description provided for @workshopsSectionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No fue posible cargar los talleres en este momento.'**
  String get workshopsSectionLoadError;

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
  /// **'Explorar mapa'**
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

  /// No description provided for @mapTopPillOneWorkshopNearby.
  ///
  /// In es, this message translates to:
  /// **'1 taller cercano'**
  String get mapTopPillOneWorkshopNearby;

  /// No description provided for @mapTopPillWorkshopsNearby.
  ///
  /// In es, this message translates to:
  /// **'{count} talleres cercanos'**
  String mapTopPillWorkshopsNearby(Object count);

  /// No description provided for @mapLoadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargando mapa'**
  String get mapLoadingTitle;

  /// No description provided for @mapLoadingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando el mapa y los talleres cercanos para ti.'**
  String get mapLoadingMessage;

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
