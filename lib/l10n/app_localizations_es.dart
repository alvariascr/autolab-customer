// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Autolab Customer';

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authLoginEmailLabel => 'Correo electrónico';

  @override
  String get authLoginEmailHint => 'Ingresa tu correo electrónico';

  @override
  String get authLoginPasswordLabel => 'Contraseña';

  @override
  String get authLoginPasswordHint => 'Ingresa tu contraseña';

  @override
  String get authLoginSubmit => 'Iniciar sesión';

  @override
  String get authLoginForgotPassword => 'Olvidé mi contraseña';

  @override
  String get authLoginSocialPrompt => 'O iniciar sesión con:';

  @override
  String get authLoginGoogle => 'Google';

  @override
  String get authLoginFacebook => 'Facebook';

  @override
  String get authLoginNoAccount => '¿No tienes cuenta?';

  @override
  String get authLoginRegisterAction => 'Registrarse';

  @override
  String get authRegisterTitle => 'Registrarse';

  @override
  String get authRegisterNameLabel => 'Nombre';

  @override
  String get authRegisterNameHint => 'Ingresa tu nombre';

  @override
  String get authRegisterEmailLabel => 'Correo electrónico';

  @override
  String get authRegisterEmailHint => 'Ingresa tu correo electrónico';

  @override
  String get authRegisterPhoneLabel => 'Teléfono';

  @override
  String get authRegisterPhoneHint => 'Ingresa tu teléfono';

  @override
  String get authRegisterPasswordLabel => 'Contraseña';

  @override
  String get authRegisterPasswordHint => 'Ingresa tu contraseña';

  @override
  String get authRegisterConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authRegisterConfirmPasswordHint => 'Repite la contraseña';

  @override
  String get authRegisterAcceptTermsPrefix => 'Acepto ';

  @override
  String get authRegisterAcceptTermsLink => 'Términos y condiciones';

  @override
  String get authRegisterSubmit => 'Registrarse';

  @override
  String get authRegisterHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authRegisterLoginAction => 'Iniciar sesión';

  @override
  String get authRegisterSuccess =>
      'Registro exitoso. Revisa tu correo para confirmar tu cuenta.';

  @override
  String get authTermsRequired => 'Debes aceptar términos y condiciones.';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorSessionExpired =>
      'La sesión ha expirado. Inicia sesión nuevamente.';

  @override
  String get authErrorUnauthorized =>
      'Tu cuenta no tiene permisos para realizar esta acción.';

  @override
  String get authErrorInvalidAuthResponse =>
      'No fue posible validar la respuesta de autenticación.';

  @override
  String get authErrorUserProfileNotFound =>
      'No encontramos el perfil asociado a esta cuenta.';

  @override
  String get authErrorUndefinedUserRole =>
      'No fue posible determinar el rol del usuario.';

  @override
  String get authErrorUnconfirmedEmail =>
      'Debes confirmar tu correo antes de iniciar sesión.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'Este correo ya se encuentra registrado.';

  @override
  String get authErrorInvalidRegisterResponse =>
      'No fue posible completar el registro en este momento.';

  @override
  String get authErrorEmailNotConfirmedRegister =>
      'Esta cuenta ya existe, pero debes confirmar tu correo.';

  @override
  String get authErrorAccountAlreadyExists =>
      'Esta cuenta ya existe. Inicia sesión.';

  @override
  String get authErrorInvalidEmail => 'El correo ingresado no es válido.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña no cumple los requisitos mínimos.';

  @override
  String authErrorRateLimit(Object remaining) {
    return 'Has excedido el número de intentos permitidos. Intenta nuevamente en $remaining.';
  }

  @override
  String get authErrorRateLimitFallbackRemaining => 'unos segundos';

  @override
  String get authErrorRegisterRateLimit =>
      'Se alcanzó el límite de intentos de registro. Intenta nuevamente en unos minutos.';

  @override
  String get authErrorRegisterUnexpected =>
      'No fue posible completar el registro. Intenta nuevamente.';

  @override
  String get authErrorSessionRestoreFailed =>
      'No fue posible restaurar la sesión del usuario.';

  @override
  String get authErrorLocalSessionRecoveryFailed =>
      'No se pudo recuperar la sesión guardada en este dispositivo.';

  @override
  String get authErrorNetworkUnavailable =>
      'Revisa tu conexión a internet e intenta nuevamente.';

  @override
  String get authErrorRequestTimeout =>
      'La solicitud tardó demasiado. Verifica tu conexión e inténtalo nuevamente.';

  @override
  String get authErrorServer =>
      'El servicio no está disponible en este momento. Intenta nuevamente más tarde.';

  @override
  String get authErrorFallback =>
      'No fue posible completar la operación. Intenta nuevamente.';

  @override
  String get authTermsPageTitle => 'Términos y condiciones';

  @override
  String get authTermsPageBody =>
      'TÉRMINOS Y CONDICIONES DE USO\n\nBienvenido a Autolab. Al acceder y utilizar esta aplicación, aceptas los siguientes términos y condiciones. Si no estás de acuerdo con alguno de ellos, te recomendamos no utilizar la app.\n\n1. USO DE LA APLICACIÓN\nAutolab es una plataforma que permite a los usuarios encontrar talleres mecánicos cercanos, consultar información y gestionar servicios relacionados con su vehículo.\n\nEl usuario se compromete a utilizar la aplicación de manera responsable, respetando las leyes vigentes y evitando cualquier uso indebido.\n\n2. REGISTRO DE USUARIO\nPara acceder a ciertas funcionalidades, es necesario registrarse proporcionando información veraz y actualizada. El usuario es responsable de mantener la confidencialidad de sus credenciales.\n\n3. PRIVACIDAD Y DATOS\nLa aplicación puede recopilar datos como nombre, correo electrónico, ubicación y número telefónico con el fin de mejorar la experiencia del usuario.\n\nEstos datos no serán compartidos con terceros sin consentimiento, salvo cuando sea requerido por ley.\n\n4. GEOLOCALIZACIÓN\nAutolab puede solicitar acceso a tu ubicación para mostrar talleres cercanos. El usuario puede aceptar o rechazar este permiso en cualquier momento desde la configuración del dispositivo.\n\n5. RESPONSABILIDAD\nAutolab actúa como intermediario entre el usuario y los talleres. No se hace responsable por la calidad del servicio brindado por terceros.\n\n6. MODIFICACIONES\nNos reservamos el derecho de modificar estos términos en cualquier momento. Se recomienda revisar esta sección periódicamente.\n\n7. ACEPTACIÓN\nAl utilizar la aplicación, el usuario acepta estos términos y condiciones en su totalidad.\n\nÚltima actualización: 2026';

  @override
  String get validationNameRequired => 'El nombre es obligatorio.';

  @override
  String get validationNameTooShort =>
      'El nombre debe tener al menos 3 caracteres.';

  @override
  String get validationEmailRequired => 'El correo electrónico es obligatorio.';

  @override
  String get validationEmailInvalid => 'Ingresa un correo electrónico válido.';

  @override
  String get validationPhoneRequired => 'El teléfono es obligatorio.';

  @override
  String get validationPhoneInvalid => 'Ingresa un teléfono válido.';

  @override
  String get validationPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get validationPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get validationConfirmPasswordRequired => 'Confirma la contraseña.';

  @override
  String get validationPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationMap => 'Mapa';

  @override
  String get navigationSearch => 'Buscar';

  @override
  String get navigationCart => 'Carrito';

  @override
  String get navigationProfile => 'Perfil';

  @override
  String get searchBarHint => 'Buscar talleres...';

  @override
  String get workshopSearchClearTooltip => 'Limpiar búsqueda';

  @override
  String get workshopSearchTitle => 'Talleres';

  @override
  String get workshopSearchRecentTitle => 'Búsquedas recientes';

  @override
  String get workshopSearchSuggestedTitle => 'Búsquedas sugeridas';

  @override
  String get workshopSearchStartMessage =>
      'Ingresa el nombre, descripción o ubicación de un taller para encontrarlo más rápido.';

  @override
  String get workshopSearchNoResults =>
      'No encontramos talleres que coincidan con tu búsqueda.';

  @override
  String get adminHomeTitle => 'Panel administrativo';

  @override
  String get adminHomeSubtitle =>
      'Vista inicial para coordinación interna de Autolab.';

  @override
  String get adminHomeHeroLabel => 'Operación del día';

  @override
  String get adminHomeHeroValue =>
      'Supervisa ingresos, agenda y seguimiento del taller desde un solo lugar.';

  @override
  String get adminHomeSummaryTitle => 'Resumen';

  @override
  String get adminHomeQuickActionsTitle => 'Accesos rápidos';

  @override
  String get adminHomeCurrentStatusTitle => 'Estado actual';

  @override
  String get adminHomeLogout => 'Cerrar sesión';

  @override
  String get adminHomeHighlightAgendaTitle => 'Agenda operativa';

  @override
  String get adminHomeHighlightAgendaDescription =>
      'Aquí podremos mostrar entradas programadas, vehículos en proceso y entregas pendientes.';

  @override
  String get adminHomeHighlightTrackingTitle => 'Seguimiento del taller';

  @override
  String get adminHomeHighlightTrackingDescription =>
      'El diseño ya separa el espacio donde luego conectaremos estados de servicio, técnicos y tiempos de atención.';

  @override
  String get adminHomeHighlightCustomersTitle => 'Relación con clientes';

  @override
  String get adminHomeHighlightCustomersDescription =>
      'También queda listo para incorporar alertas de aprobación, historial y comunicación post-servicio.';

  @override
  String get adminHomeQuickActionRegisterTitle => 'Registrar ingreso';

  @override
  String get adminHomeQuickActionRegisterDescription =>
      'Crear una nueva recepción de vehículo.';

  @override
  String get adminHomeQuickActionOrdersTitle => 'Ver órdenes abiertas';

  @override
  String get adminHomeQuickActionOrdersDescription =>
      'Consultar trabajos que siguen en ejecución.';

  @override
  String get adminHomeQuickActionDeliveriesTitle => 'Revisar entregas';

  @override
  String get adminHomeQuickActionDeliveriesDescription =>
      'Identificar unidades listas para salida.';

  @override
  String get adminHomeStatusCapacityLabel => 'Capacidad del taller';

  @override
  String get adminHomeStatusCapacityCaption => 'Carga saludable';

  @override
  String get adminHomeStatusCriticalDeliveriesLabel => 'Entregas críticas';

  @override
  String get adminHomeStatusCriticalDeliveriesCaption => 'Revisión prioritaria';

  @override
  String get adminHomeStatusPendingApprovalsLabel => 'Aprobaciones pendientes';

  @override
  String get adminHomeStatusPendingApprovalsCaption => 'Esperando respuesta';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileAccountTitle => 'Tu cuenta';

  @override
  String get profileAccountSubtitle =>
      'Administra tu sesión y revisa la información principal de tu perfil desde este apartado.';

  @override
  String get profileSessionTitle => 'Sesión';

  @override
  String get profileSessionSubtitle =>
      'Cierra tu sesión cuando quieras desde aquí.';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get locationHeaderEyebrowDeliverNow => 'Entregar ahora';

  @override
  String get locationHeaderEyebrowConfirmingAccess => 'Confirmando acceso';

  @override
  String get locationHeaderEyebrowLoading => 'Buscando cerca de ti';

  @override
  String get locationHeaderEyebrowPermission => 'Permiso de ubicación';

  @override
  String get locationHeaderEyebrowGpsOff => 'Ubicación desactivada';

  @override
  String get locationHeaderEyebrowRestricted => 'Ubicación restringida';

  @override
  String get locationHeaderEyebrowError => 'No pudimos confirmar tu zona';

  @override
  String get locationHeaderTitleChooseAddress => 'Elegir dirección';

  @override
  String get locationHeaderTitleOpenSettings => 'Abrir configuración';

  @override
  String get locationHeaderTitleEnableGps => 'Encender GPS';

  @override
  String get locationHeaderTitleUnavailable => 'Ubicación no disponible';

  @override
  String get locationHeaderTitleConfirmAccess =>
      'Confirma el acceso a tu ubicación';

  @override
  String get locationHeaderTitleError => 'No pudimos confirmar tu dirección';

  @override
  String get locationHeaderTitleLoading => 'Buscando tu ubicación actual';

  @override
  String get locationHeaderTitleSuccessFallback => 'Ubicación detectada';

  @override
  String get locationHeaderSubtitleChooseAddress =>
      'Usa tu ubicación actual para descubrir talleres y servicios cercanos.';

  @override
  String get locationHeaderSubtitleOpenSettings =>
      'Necesitamos que habilites el permiso desde la configuración del teléfono.';

  @override
  String get locationHeaderSubtitleEnableGps =>
      'Activa la ubicación del dispositivo para ver resultados cercanos.';

  @override
  String get locationHeaderSubtitleConfirmAccess =>
      'Estamos esperando tu respuesta para poder ubicar tu zona de entrega.';

  @override
  String get locationHeaderSubtitleLoading =>
      'Estamos consultando la ubicación del dispositivo para mostrarte talleres cercanos.';

  @override
  String get locationHeaderSubtitleErrorFallback =>
      'Intenta de nuevo en unos segundos.';

  @override
  String get locationHeaderSubtitleRestrictedFallback =>
      'La ubicación no está disponible en este dispositivo.';

  @override
  String get locationErrorPermissionRestricted =>
      'La ubicación está restringida en este dispositivo.';

  @override
  String get locationErrorPermissionRequired =>
      'Activa tu ubicación para ver talleres y servicios cercanos.';

  @override
  String get locationErrorServiceDisabled =>
      'Enciende el GPS del dispositivo para continuar.';

  @override
  String get locationErrorActionFailed =>
      'No fue posible completar la acción de ubicación. Intenta nuevamente.';

  @override
  String get locationErrorRequestTimeout =>
      'La ubicación tardó demasiado en responder. Intenta nuevamente.';

  @override
  String get locationErrorInvalidCurrentLocation =>
      'No pudimos obtener una ubicación válida. Intenta nuevamente.';

  @override
  String get locationErrorConfigurationIncomplete =>
      'La ubicación no está disponible en este momento. Intenta más tarde.';

  @override
  String get locationSheetTitle => 'Selecciona dónde entregar';

  @override
  String get locationSheetSubtitle =>
      'Puedes usar tu ubicación actual o elegir una dirección guardada más adelante.';

  @override
  String get locationSheetCurrentLocationDefaultTitle =>
      'Usar ubicación actual';

  @override
  String get locationSheetCurrentLocationDefaultSubtitle =>
      'Usa el GPS del teléfono para ver talleres y servicios cerca de ti.';

  @override
  String get locationSheetCurrentLocationSuccessTitle =>
      'Actualizar ubicación actual';

  @override
  String get locationSheetCurrentLocationSuccessSubtitle =>
      'Volver a consultar tu ubicación para actualizar los resultados.';

  @override
  String get locationSheetCurrentLocationOpenSettingsTitle =>
      'Abrir configuración';

  @override
  String get locationSheetCurrentLocationOpenSettingsSubtitle =>
      'Habilita el permiso de ubicación desde la configuración del teléfono.';

  @override
  String get locationSheetCurrentLocationEnableGpsTitle => 'Encender GPS';

  @override
  String get locationSheetCurrentLocationEnableGpsSubtitle =>
      'Activa la ubicación del dispositivo para ver talleres cercanos.';

  @override
  String get locationSheetCurrentLocationWaitingTitle => 'Esperando permiso';

  @override
  String get locationSheetCurrentLocationWaitingSubtitle =>
      'Estamos esperando tu respuesta para acceder a la ubicación.';

  @override
  String get locationSheetWriteAddressTitle => 'Escribir dirección';

  @override
  String get locationSheetWriteAddressSubtitle =>
      'Lo conectamos en el siguiente paso del home.';

  @override
  String get locationSheetHomeTitle => 'Casa';

  @override
  String get locationSheetWorkTitle => 'Trabajo';

  @override
  String get locationSheetSavedAddressSubtitle =>
      'Próximamente podrás guardar tus direcciones favoritas.';

  @override
  String get workshopsSectionTitle => 'Talleres cercanos';

  @override
  String get workshopsSectionSubtitle =>
      'Explora opciones cercanas sin salir del home.';

  @override
  String get workshopsSectionLoadError =>
      'No fue posible cargar los talleres en este momento.';

  @override
  String get workshopErrorLoadFailed =>
      'No fue posible cargar los talleres en este momento.';

  @override
  String get workshopErrorNetwork =>
      'Revisa tu conexión para consultar los talleres cercanos.';

  @override
  String workshopCardDistancePrefix(Object distance) {
    return 'A $distance';
  }

  @override
  String workshopCardCoveragePrefix(Object distance) {
    return 'Cobertura $distance';
  }

  @override
  String get workshopCardDescriptionFallback => 'Sin descripción disponible';

  @override
  String get workshopEmptySearchingNearby => 'Buscando talleres cercanos...';

  @override
  String get workshopEmptyEnableLocation =>
      'Activa tu ubicación para ver talleres cercanos.';

  @override
  String get workshopEmptyLocationErrorFallback =>
      'No pudimos obtener tu ubicación para buscar talleres cercanos.';

  @override
  String get workshopEmptyNoNearby =>
      'No encontramos talleres cercanos a tu ubicación actual.';

  @override
  String get mapPageTitle => 'Mapa';

  @override
  String get mapTopPillExplore => 'Explorar mapa';

  @override
  String get mapTopPillLoadingWorkshops => 'Cargando talleres';

  @override
  String get mapTopPillNoWorkshops => 'Sin talleres';

  @override
  String get mapTopPillOneWorkshopNearby => '1 taller cercano';

  @override
  String mapTopPillWorkshopsNearby(Object count) {
    return '$count talleres cercanos';
  }

  @override
  String get mapLoadingTitle => 'Cargando mapa';

  @override
  String get mapLoadingMessage =>
      'Estamos preparando el mapa y los talleres cercanos para ti.';

  @override
  String get mapAttributionOpenStreetMap => 'OpenStreetMap contributors';

  @override
  String get mapWorkshopsLoadError =>
      'No fue posible cargar los talleres en este momento.';

  @override
  String get mapWorkshopsNetworkError =>
      'Revisa tu conexión para consultar los talleres cercanos.';

  @override
  String get mapErrorTitle => 'No pudimos cargar el mapa';

  @override
  String get mapErrorMessage =>
      'Revisa tu conexión e inténtalo nuevamente. Los talleres seguirán disponibles cuando el mapa se recupere.';

  @override
  String get mapRetry => 'Reintentar';

  @override
  String get mapYourLocation => 'Tu ubicación';

  @override
  String get mapZoomInTooltip => 'Acercar';

  @override
  String get mapZoomOutTooltip => 'Alejar';

  @override
  String mapInfoDistancePrefix(Object distance) {
    return 'A $distance';
  }

  @override
  String mapInfoCoveragePrefix(Object distance) {
    return 'Cobertura $distance';
  }

  @override
  String get mapSheetFallbackAddress => 'Ubicación disponible en el mapa.';

  @override
  String get mapSheetLabelWorkshop => 'Taller';

  @override
  String get mapSheetLabelCoverage => 'Alcance';

  @override
  String get mapSheetFallbackDescription =>
      'Este taller está listo para atender solicitudes cerca de tu ubicación.';

  @override
  String mapMarkerTooltipWithAddress(Object name, Object address) {
    return '$name\n$address';
  }

  @override
  String mapMarkerTooltipWithoutAddress(Object name) {
    return '$name';
  }

  @override
  String get homePlaceholderTitle => 'Explora talleres cerca de ti';

  @override
  String get homePlaceholderSubtitle =>
      'Este espacio queda libre para integrar carruseles, listados y resultados dinámicos sin mezclar contenido demo dentro del home.';
}
