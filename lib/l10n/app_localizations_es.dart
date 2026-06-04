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
  String get authForgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get authForgotPasswordSubtitle =>
      'Ingresa el correo de tu cuenta y te enviaremos un enlace para crear una nueva contraseña.';

  @override
  String get authForgotPasswordSubmit => 'Enviar enlace';

  @override
  String get authPasswordResetEmailSent =>
      'Te enviamos un enlace de recuperación. Revisa tu correo.';

  @override
  String get authResetPasswordTitle => 'Nueva contraseña';

  @override
  String get authResetPasswordSubtitle =>
      'Ingresa una nueva contraseña para volver a entrar a tu cuenta.';

  @override
  String get authResetPasswordNewPasswordLabel => 'Nueva contraseña';

  @override
  String get authResetPasswordNewPasswordHint => 'Ingresa tu nueva contraseña';

  @override
  String get authResetPasswordSubmit => 'Actualizar contraseña';

  @override
  String get authPasswordResetSuccess =>
      'Tu contraseña fue actualizada. Inicia sesión nuevamente.';

  @override
  String get authPasswordResetBackToLogin => 'Volver a iniciar sesión';

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
  String get authEmailConfirmedLoginMessage =>
      'Tu correo fue confirmado. Ya puedes iniciar sesión.';

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
  String get searchBarHint => 'Buscar en Autolab';

  @override
  String get workshopSearchClearTooltip => 'Limpiar búsqueda';

  @override
  String get workshopSearchTitle => 'Talleres';

  @override
  String get workshopSearchRecentTitle => 'Búsquedas recientes';

  @override
  String get workshopSearchRecentClearAction => 'Limpiar';

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
  String get profileAppointmentsTitle => 'Mis citas';

  @override
  String get profileAppointmentsSubtitle =>
      'Consulta tus citas próximas, pasadas y canceladas.';

  @override
  String get myAppointmentsTitle => 'Mis citas';

  @override
  String get myAppointmentsNotificationsTooltip => 'Notificaciones';

  @override
  String get myAppointmentsSubtitle => 'Consulta tus reservas de servicios';

  @override
  String get myAppointmentsLoadErrorTitle => 'No pudimos cargar tus citas';

  @override
  String get myAppointmentsRetryMessage =>
      'Intenta nuevamente en unos segundos.';

  @override
  String get myAppointmentsRetryAction => 'Reintentar';

  @override
  String get myAppointmentsSearchWorkshopsAction => 'Buscar talleres';

  @override
  String get myAppointmentsUpcomingEmptyTitle => 'No tienes citas próximas';

  @override
  String get myAppointmentsPastEmptyTitle => 'No tienes citas pasadas';

  @override
  String get myAppointmentsCanceledEmptyTitle => 'No tienes citas canceladas';

  @override
  String get myAppointmentsUpcomingEmptyMessage =>
      'Cuando reserves un servicio en un taller, aparecerá aquí.';

  @override
  String get myAppointmentsPastEmptyMessage =>
      'Tus servicios completados o vencidos aparecerán aquí.';

  @override
  String get myAppointmentsCanceledEmptyMessage =>
      'Las reservas canceladas aparecerán en este apartado.';

  @override
  String get myAppointmentsUpcomingTab => 'Próximas';

  @override
  String get myAppointmentsPastTab => 'Completada';

  @override
  String get myAppointmentsCanceledTab => 'Canceladas';

  @override
  String get myAppointmentsNewAppointmentPrompt =>
      '¿Necesitas agendar una nueva cita?';

  @override
  String get myAppointmentsStatusCanceled => 'Cancelada';

  @override
  String get myAppointmentsStatusNoShow => 'No asistió';

  @override
  String get myAppointmentsStatusCompleted => 'Completada';

  @override
  String get myAppointmentsStatusCheckedIn => 'Registrada';

  @override
  String get myAppointmentsStatusInProgress => 'En proceso';

  @override
  String get myAppointmentsStatusExpired => 'Expirada';

  @override
  String get myAppointmentsStatusConfirmed => 'Programada';

  @override
  String get vehiclesTitle => 'Mis vehículos';

  @override
  String get vehiclesProfileSubtitle =>
      'Administra los vehículos que usas para reservar citas.';

  @override
  String get vehiclesSubtitle =>
      'Guarda tus vehículos una sola vez y selecciónalos al agendar en cualquier taller.';

  @override
  String get vehiclesAddAction => 'Agregar vehículo';

  @override
  String get vehiclesEditAction => 'Editar vehículo';

  @override
  String get vehiclesEmpty => 'Aún no tienes vehículos guardados.';

  @override
  String get vehiclesLoadFailed =>
      'No pudimos cargar tus vehículos. Intenta nuevamente.';

  @override
  String get vehiclesFormTitle => 'Agregar vehículo';

  @override
  String get vehiclesEditFormTitle => 'Editar vehículo';

  @override
  String get vehiclesPlateLabel => 'Placa';

  @override
  String get vehiclesPlateRequired => 'Ingresa la placa del vehículo.';

  @override
  String get vehiclesTypeLabel => 'Tipo de vehículo';

  @override
  String get vehiclesTypeCar => 'Automóvil';

  @override
  String get vehiclesTypeMotorcycle => 'Motocicleta';

  @override
  String get vehiclesTypePickup => 'Pickup';

  @override
  String get vehiclesTypeSuv => 'SUV';

  @override
  String get vehiclesTypeTruck => 'Camión';

  @override
  String get vehiclesBrandLabel => 'Marca';

  @override
  String get vehiclesModelLabel => 'Modelo';

  @override
  String get vehiclesYearLabel => 'Año';

  @override
  String get vehiclesColorLabel => 'Color';

  @override
  String get vehiclesFuelLabel => 'Combustible';

  @override
  String get vehiclesFuelGasoline => 'Gasolina';

  @override
  String get vehiclesFuelDiesel => 'Diésel';

  @override
  String get vehiclesFuelElectric => 'Eléctrico';

  @override
  String get vehiclesFuelHybrid => 'Híbrido';

  @override
  String get vehiclesTransmissionLabel => 'Transmisión';

  @override
  String get vehiclesTransmissionManual => 'Manual';

  @override
  String get vehiclesTransmissionAutomatic => 'Automática';

  @override
  String get vehiclesSaveAction => 'Guardar vehículo';

  @override
  String get vehiclesSaveFailed =>
      'No pudimos guardar el vehículo. Revisa la información e inténtalo de nuevo.';

  @override
  String get vehiclesPlateAlreadyExists =>
      'Esta placa ya está registrada en tus vehículos. Selecciona ese vehículo de la lista o elimina el registro anterior.';

  @override
  String get vehiclesDeleteTitle => 'Eliminar vehículo';

  @override
  String vehiclesDeleteMessage(String plate) {
    return '¿Quieres eliminar el vehículo $plate de tus vehículos?';
  }

  @override
  String get vehiclesCancelAction => 'Cancelar';

  @override
  String get vehiclesDeleteAction => 'Eliminar';

  @override
  String get vehiclesDeleteFailed =>
      'No pudimos eliminar el vehículo. Intenta nuevamente.';

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
  String get workshopProfileLoadError =>
      'No fue posible cargar el perfil del taller en este momento.';

  @override
  String get workshopProfileNotFound => 'No encontramos este taller.';

  @override
  String get workshopProfileScheduleAction => 'Agendar cita';

  @override
  String get workshopProfileCallAction => 'Llamar';

  @override
  String get workshopProfileOpenLocationAction => 'Abrir ubicación';

  @override
  String get workshopProfileDirectionsAction => 'Dirígete ahí';

  @override
  String get workshopProfileScheduleSoon =>
      'Próximamente podrás agendar una cita desde aquí.';

  @override
  String get workshopProfileActionError =>
      'No fue posible abrir esta acción. Intenta nuevamente.';

  @override
  String get workshopProfileDeliveryTab => 'Entrega';

  @override
  String get workshopProfilePickupTab => 'Para llevar';

  @override
  String get workshopProfileAboutTitle => 'Acerca del taller';

  @override
  String get workshopProfileDetailsTitle => 'Detalles';

  @override
  String get workshopProfileHomeServiceTitle => 'Servicio a domicilio';

  @override
  String get workshopProfileHomeServiceAvailable => 'Disponible';

  @override
  String get workshopProfileHomeServiceUnavailable => 'No disponible';

  @override
  String get workshopProfileMobileServiceLabel => 'Servicio móvil';

  @override
  String get workshopProfileCoverageTitle => 'Cobertura';

  @override
  String workshopProfileCoverageValue(Object distance) {
    return '$distance km de radio';
  }

  @override
  String get workshopProfileCoverageAreaSubtitle => 'Área de atención';

  @override
  String get workshopProfileCoverageUnavailable => 'Cobertura no disponible';

  @override
  String get workshopProfilePhoneTitle => 'Teléfono';

  @override
  String get workshopProfileServicesTitle => 'Servicios';

  @override
  String get workshopProfileServicesEmpty =>
      'Este taller aún no tiene servicios publicados.';

  @override
  String get workshopProfileProductsTitle => 'Productos';

  @override
  String get workshopProfileProductsEmpty =>
      'Este taller aún no tiene productos publicados.';

  @override
  String get workshopProfileProductSearchHint =>
      'Buscar productos en este taller...';

  @override
  String get workshopProfileProductsNoResults =>
      'No encontramos productos que coincidan con tu búsqueda.';

  @override
  String get workshopProfileBusinessHoursTitle => 'Horario';

  @override
  String get workshopProfileBusinessHoursEmpty => 'Horario no disponible';

  @override
  String get workshopProfileClosed => 'Cerrado';

  @override
  String workshopProfileOpenUntil(Object time) {
    return 'Abierto hasta las $time';
  }

  @override
  String get workshopProfileUnknownDay => 'Día no disponible';

  @override
  String get workshopProfilePaymentMethodsTitle => 'Métodos de pago';

  @override
  String get workshopProfilePaymentMethodsEmpty =>
      'Métodos de pago no disponibles.';

  @override
  String get appointmentSelectServiceRequired =>
      'Selecciona un servicio para continuar.';

  @override
  String get appointmentSelectDateTimeRequired =>
      'Selecciona un día y una hora.';

  @override
  String get appointmentStepVehicle => 'Seleccionar tipo de vehículo';

  @override
  String get appointmentStepWorkshop => 'Taller seleccionado';

  @override
  String get appointmentStepService => 'Seleccionar servicio';

  @override
  String get appointmentStepProducts => 'Productos adicionales';

  @override
  String get appointmentStepDateTime => 'Seleccionar día y hora';

  @override
  String get appointmentStepCustomerInfo => 'Información del cliente';

  @override
  String get appointmentStepConfirmation => 'Confirmación';

  @override
  String get appointmentStepPayment => 'Método de pago';

  @override
  String get appointmentVehicleCar => 'AUTOMÓVIL';

  @override
  String get appointmentVehicleMotorcycle => 'MOTOCICLETA / CUADRACICLO';

  @override
  String get appointmentVehicleLightLoad => 'CARGA LIVIANA';

  @override
  String get appointmentVehicleTaxi => 'TAXI';

  @override
  String get appointmentVehicleHeavyLoad => 'CARGA PESADA';

  @override
  String get appointmentVehicleBus => 'AUTOBÚS-MICROBÚS';

  @override
  String get appointmentVehicleSpecialEquipment => 'Equipos Especiales';

  @override
  String get appointmentVehicleSpecialEquipmentSubtitle =>
      'No transitan por vías públicas';

  @override
  String get appointmentVehicleTrailer => 'REMOLQUE-SEMIREMOLQUE';

  @override
  String get appointmentVehiclePublicTransport =>
      'AUTOBÚS-MICROBÚS TRANSPORTE PÚBLICO';

  @override
  String get appointmentProductsSwitchLabel =>
      'Necesito productos para este servicio';

  @override
  String get appointmentProductsOptionalMessage =>
      'Puedes continuar sin agregar productos.';

  @override
  String get appointmentProductsEmpty =>
      'Este taller no tiene productos adicionales disponibles.';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

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
  String get mapSearchHint => 'Buscar en Autolab';

  @override
  String get mapSearchFiltersTooltip => 'Filtros';

  @override
  String get mapSearchClearTooltip => 'Limpiar';

  @override
  String get mapFilterOffers => 'Ofertas';

  @override
  String get mapFilterService => 'Servicio';

  @override
  String get mapFilterTopRated => 'Mejor calificado';

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
  String get mapSheetNearbyWorkshopsTitle => 'Talleres cerca de ti';

  @override
  String get mapSheetOneResult => '1 resultado';

  @override
  String mapSheetResults(Object count) {
    return '$count resultados';
  }

  @override
  String get mapSheetNoSearchResults =>
      'No encontramos talleres para esa búsqueda.';

  @override
  String get mapSheetProductsLabel => 'Productos';

  @override
  String get mapSheetViewOnMapTooltip => 'Ver en mapa';

  @override
  String mapSheetProductSearchResults(Object count, Object query) {
    return '$count resultados para \"$query\"';
  }

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

  @override
  String get appointmentCreatedSuccess => 'Tu cita fue creada correctamente.';

  @override
  String get appointmentCreateFailed =>
      'No pudimos crear la cita. Inténtalo nuevamente.';

  @override
  String get appointmentVehicleValidationFailed =>
      'No pudimos validar el vehículo.';

  @override
  String get appointmentScheduleValidationFailedShort =>
      'No pudimos validar el horario.';

  @override
  String get appointmentDateUnavailable =>
      'Ese día ya no tiene horarios disponibles. Selecciona otra fecha.';

  @override
  String get appointmentScheduleRequired =>
      'Selecciona fecha y hora para continuar.';

  @override
  String get appointmentSlotUnavailable =>
      'Ese horario acaba de ocuparse. Selecciona otra hora.';

  @override
  String get appointmentScheduleValidationFailed =>
      'No pudimos validar el horario. Inténtalo nuevamente.';

  @override
  String get appointmentVehiclePlateRequired =>
      'Selecciona un vehículo para continuar.';

  @override
  String get appointmentVehiclePlateConflict =>
      'Ya tienes un vehículo con esta placa. Selecciónalo de la lista o edítalo desde Gestionar vehículos.';

  @override
  String get appointmentVehicleValidationFailedDetailed =>
      'No pudimos validar el vehículo. Revisa la información e inténtalo de nuevo.';

  @override
  String get appointmentBookingIncomplete =>
      'Revisa que el vehículo, servicio, fecha y hora estén completos.';

  @override
  String get appointmentAuthRequired =>
      'Inicia sesión para poder reservar tu cita.';

  @override
  String get appointmentDateTimeInPast =>
      'Selecciona una fecha y hora disponible más adelante.';

  @override
  String get appointmentCustomerNameRequired =>
      'Completa tu nombre en el perfil antes de reservar.';

  @override
  String get appointmentCustomerPhoneRequired =>
      'Completa tu teléfono en el perfil antes de reservar.';

  @override
  String get appointmentServiceNotSchedulable =>
      'Este servicio ya no está disponible para agendar.';

  @override
  String get appointmentVehicleNotOwned =>
      'No pudimos usar ese vehículo con tu usuario.';

  @override
  String get appointmentVehiclePlateRequiredForBooking =>
      'Ingresa la placa del vehículo para reservar.';

  @override
  String get appointmentBookingConfigurationFailed =>
      'La reserva no está configurada correctamente. Contacta al equipo de soporte.';

  @override
  String get appointmentStepVehicleInfo => 'Información del vehículo';

  @override
  String get appointmentWorkshopFallbackDescription =>
      'Servicio y mantenimiento automotriz';

  @override
  String get appointmentVehiclePlateLabel => 'Placa';

  @override
  String get appointmentVehicleTypeLabel => 'Tipo de vehículo';

  @override
  String get appointmentVehicleTypeCar => 'Automóvil';

  @override
  String get appointmentVehicleTypeMotorcycle => 'Motocicleta';

  @override
  String get appointmentVehicleTypePickup => 'Pickup';

  @override
  String get appointmentVehicleTypeSuv => 'SUV';

  @override
  String get appointmentVehicleTypeTruck => 'Camión';

  @override
  String get appointmentVehicleTypeBus => 'Bus';

  @override
  String get appointmentVehicleTypeTrailer => 'Remolque';

  @override
  String get appointmentVehicleTypeSpecialEquipment => 'Equipo especial';

  @override
  String get appointmentVehicleBrandLabel => 'Marca';

  @override
  String get appointmentVehicleModelLabel => 'Modelo';

  @override
  String get appointmentVehicleYearLabel => 'Año';

  @override
  String get appointmentVehicleColorLabel => 'Color';

  @override
  String get appointmentVehicleFuelLabel => 'Combustible';

  @override
  String get appointmentVehicleFuelGasoline => 'Gasolina';

  @override
  String get appointmentVehicleFuelDiesel => 'Diésel';

  @override
  String get appointmentVehicleFuelElectric => 'Eléctrico';

  @override
  String get appointmentVehicleFuelHybrid => 'Híbrido';

  @override
  String get appointmentVehicleTransmissionLabel => 'Transmisión';

  @override
  String get appointmentVehicleTransmissionManual => 'Manual';

  @override
  String get appointmentVehicleTransmissionAutomatic => 'Automática';

  @override
  String get appointmentMyVehiclesTitle => 'Mis vehículos';

  @override
  String get appointmentAddVehicleShortAction => 'Vehículo';

  @override
  String get appointmentNewVehicleAction => '+ Nuevo';

  @override
  String get appointmentNoVehiclesForWorkshop =>
      'Aún no tienes vehículos guardados.';

  @override
  String get appointmentNoSchedulableServices =>
      'Este taller no tiene servicios disponibles para agendar.';

  @override
  String get appointmentBackAction => 'ANTERIOR';

  @override
  String get appointmentExitAction => 'SALIR';

  @override
  String get appointmentNewServiceAction => 'NUEVO SERVICIO';

  @override
  String get appointmentCreatingAction => 'CREANDO';

  @override
  String get appointmentFinishAction => 'FINALIZAR';

  @override
  String get appointmentPayAction => 'PAGAR';

  @override
  String get appointmentNextAction => 'SIGUIENTE';

  @override
  String get appointmentSelectedDayLegend => 'Día seleccionado';

  @override
  String get appointmentAvailableDayLegend => 'Día disponible';

  @override
  String get appointmentOccupiedDayLegend => 'Día ocupado';

  @override
  String get appointmentAvailableHoursTitle => 'Horas disponibles';

  @override
  String get appointmentAvailableHoursLoading =>
      'Estamos consultando los horarios disponibles.';

  @override
  String get appointmentAvailableHoursFailed =>
      'No pudimos cargar la disponibilidad. Inténtalo nuevamente.';

  @override
  String get appointmentAvailableHoursEmpty =>
      'No hay horarios disponibles para este día.';

  @override
  String get appointmentPendingDate => 'fecha pendiente';

  @override
  String get appointmentConfirmationReadyTitle => 'Cita lista para confirmar';

  @override
  String get appointmentPendingPlate => 'Placa pendiente';

  @override
  String get appointmentServiceLabel => 'Servicio';

  @override
  String get appointmentPendingService => 'Servicio pendiente';

  @override
  String get appointmentDateLabel => 'Fecha';

  @override
  String get appointmentPaymentCard => 'Tarjeta';

  @override
  String get appointmentPaymentSinpe => 'SINPE Móvil';

  @override
  String get appointmentPaymentCardSubtitle =>
      'Pago con tarjeta de crédito o débito.';

  @override
  String get appointmentPaymentSinpeSubtitle =>
      'Recibirás las instrucciones para completar el pago.';

  @override
  String get appointmentConfirmationDeliveryMessage =>
      'Recibirás los detalles por correo o WhatsApp.';

  @override
  String get appointmentWorkshopLabel => 'Taller';

  @override
  String get appointmentProductsLabel => 'Productos';

  @override
  String get appointmentNoAdditionalProducts => 'Sin productos adicionales.';

  @override
  String get appointmentTotalToPayLabel => 'Total a pagar';

  @override
  String get appointmentPriceToConfirm => 'Por confirmar';
}
