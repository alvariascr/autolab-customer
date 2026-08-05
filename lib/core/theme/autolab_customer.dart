import 'package:flutter/material.dart';

class AutolabCustomer {
  const AutolabCustomer._();

  // Fuente principal usada por la identidad visual del módulo cliente.
  static const String primaryFont = 'Poppins';

  // Color principal de marca para acciones, estados activos y elementos clave.
  static const Color primary = Color(0xFFFF281B);
  static const Color primaryHover = Color(0xFFE62016);
  static const Color primaryPressed = Color(0xFFCC1F16);

  // Color secundario de marca, usado principalmente para textos fuertes.
  static const Color secondary = Color(0xFF000000);

  // Colores neutrales base para fondos, textos suaves y bordes.
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFA9A9A9);
  static const Color background = Color(0xFFF4E9E9);
  static const Color border = Color(0xFFE5E5E5);
  static const Color shadowBlackLight = Color(0x10000000);
  static const Color shadowBlackSoft = Color(0x12000000);
  static const Color shadowBlackMedium = Color(0x18000000);
  static const Color shadowBlackStrong = Color(0x22000000);
  static const Color shadowBlackIntense = Color(0x24000000);
  static const Color shadowBlack26 = Color(0x42000000);
  static const Color overlayBlackLight = Color(0x66000000);
  static const Color overlayBlackDark = Color(0x99000000);
  static const Color overlayWhiteLight = Color(0x26FFFFFF);
  static const Color overlayWhiteStrong = Color(0xCCFFFFFF);

  // Colores funcionales para comunicar estados de la interfaz.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color successText = Color(0xFF167A3A);
  static const Color successSoftBackground = Color(0xFFEAF7EF);
  static const Color warningText = Color(0xFFB26A00);
  static const Color warningSoftBackground = Color(0xFFFFF5DF);
  static const Color errorDarkText = Color(0xFFB3261E);
  static const Color errorSoftBackground = Color(0xFFFFECEA);

  // Colores asignados a los estados de las citas.
  static const Color appointmentConfirmed = success;
  static const Color appointmentPending = warning;
  static const Color appointmentCancelled = error;
  static const Color appointmentCompleted = secondary;

  // Colores reutilizables para navegación y badges informativos.
  static const Color navigationActive = primary;
  static const Color navigationInactive = gray;
  static const Color ratingBadge = success;
  static const Color distanceBadge = background;

  // Paleta base para pantallas que usan modo oscuro.
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = white;
  static const Color darkSecondaryText = gray;

  // Colores específicos del flujo de autenticación.
  static const Color authBackground = Color(0xFF050606);
  static const Color authFieldBackground = Color(0xFF1A1A1A);
  static const Color authFieldText = Color(0xFFF4E9E9);
  static const Color authPlaceholder = Color(0xFF9A9A9A);
  static const Color authSocialBorder = Color(0xFF3A3A3A);
  static const Color authSuccessBackground = Color(0xFFF0FDF4);
  static const Color authSuccessBorder = Color(0xFFBBF7D0);
  static const Color authSuccessShadow = Color(0x1422C55E);
  static const Color authSuccessIconBackground = Color(0xFFDCFCE7);
  static const Color authSuccessIcon = Color(0xFF16A34A);
  static const Color authSuccessText = Color(0xFF166534);
  static const Color authErrorBackground = Color(0xFFFFF1F0);
  static const Color authErrorBorder = Color(0xFFFFC9C5);
  static const Color authErrorShadow = Color(0x14D92D20);
  static const Color authErrorIconBackground = Color(0xFFFFE2DF);
  static const Color authErrorIcon = Color(0xFFD92D20);
  static const Color authErrorText = Color(0xFFB42318);
  static const Color facebook = Color(0xFF1877F2);

  // Colores neutrales usados por el rediseño del módulo cliente.
  static const Color customerDarkBackground = authBackground;
  static const Color customerDarkSurface = authFieldBackground;
  static const Color customerDarkText = authFieldText;
  static const Color customerDarkDivider = Color(0xFF171717);
  static const Color customerDarkBorder = Color(0xFF3A3A3A);
  static const Color customerDarkHint = Color(0xFF5F5F5F);
  static const Color customerDarkImageFallback = Color(0xFF242424);

  static const Color customerLightBackground = Color(0xFFFFFFFF);
  static const Color customerLightSurface = Color(0xFFF3F3F3);
  static const Color customerLightSoftSurface = Color(0xFFE7E7E7);
  static const Color customerLightText = Color(0xFF111111);
  static const Color customerLightSecondaryText = Color(0xFF606060);
  static const Color customerLightDisabledText = Color(0xFF8A8A8A);
  static const Color customerLightDivider = Color(0xFFD7D7D7);
  static const Color customerLightHint = Color(0xFF606060);
  static const Color customerLightMapFallback = Color(0xFFE8EEF3);

  /// Devuelve el fondo principal para pantallas del módulo cliente.
  static Color customerBackgroundColor(BuildContext context) {
    return isDark(context) ? customerDarkBackground : customerLightBackground;
  }

  /// Devuelve el color de superficie para cards y contenedores del cliente.
  static Color customerSurfaceColor(BuildContext context) {
    return isDark(context) ? customerDarkSurface : customerLightSurface;
  }

  /// Devuelve el color de superficie elevada para cards oscuras/blancas.
  static Color customerElevatedSurfaceColor(BuildContext context) {
    return isDark(context) ? customerDarkSurface : white;
  }

  /// Devuelve una superficie suave para tiles o bloques secundarios.
  static Color customerSoftSurfaceColor(BuildContext context) {
    return isDark(context) ? customerDarkSurface : customerLightSoftSurface;
  }

  /// Devuelve el color principal de texto para pantallas cliente.
  static Color customerTextColor(BuildContext context) {
    return isDark(context) ? customerDarkText : customerLightText;
  }

  /// Devuelve el color de texto secundario para pantallas cliente.
  static Color customerSecondaryTextColor(BuildContext context) {
    return isDark(context) ? darkSecondaryText : customerLightSecondaryText;
  }

  /// Devuelve el color para textos o iconos deshabilitados del cliente.
  static Color customerDisabledTextColor(BuildContext context) {
    return isDark(context) ? customerDarkHint : customerLightDisabledText;
  }

  /// Devuelve el color de divisores para pantallas cliente.
  static Color customerDividerColor(BuildContext context) {
    return isDark(context) ? customerDarkDivider : customerLightDivider;
  }

  /// Devuelve el color de borde para cards, chips e inputs del cliente.
  static Color customerBorderColor(BuildContext context) {
    return isDark(context) ? customerDarkBorder : customerLightDivider;
  }

  /// Devuelve el color para placeholders o hints del cliente.
  static Color customerHintColor(BuildContext context) {
    return isDark(context) ? customerDarkHint : customerLightHint;
  }

  /// Devuelve el color de fondo para botones/iconos invertidos del cliente.
  static Color customerInvertedSurfaceColor(BuildContext context) {
    return isDark(context) ? customerDarkText : customerLightText;
  }

  /// Devuelve el color de contenido sobre superficies invertidas.
  static Color customerOnInvertedSurfaceColor(BuildContext context) {
    return isDark(context) ? customerDarkBackground : white;
  }

  /// Devuelve el color fallback para imágenes que no cargan.
  static Color customerImageFallbackColor(BuildContext context) {
    return isDark(context)
        ? customerDarkImageFallback
        : customerLightSoftSurface;
  }

  /// Devuelve el color de fondo para chips del módulo cliente.
  /// Devuelve el color fallback para mapas sin coordenadas.
  static Color customerMapFallbackColor(BuildContext context) {
    return isDark(context) ? customerDarkSurface : customerLightMapFallback;
  }

  static Color customerChipBackgroundColor(BuildContext context) {
    return isDark(context) ? customerDarkBorder : customerLightSurface;
  }

  /// Indica si el contexto actual está usando el tema oscuro.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Indica si el ancho disponible corresponde a un teléfono pequeño.
  static bool isCompactWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  /// Indica si la altura disponible es reducida.
  static bool isCompactHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 720;
  }

  /// Indica si el ancho disponible corresponde a tablet o escritorio.
  static bool isTabletWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 700;
  }

  /// Devuelve un valor numérico según el tamaño de pantalla.
  static double responsiveDouble(
    BuildContext context, {
    required double compact,
    required double regular,
    double? tablet,
  }) {
    if (isTabletWidth(context)) {
      return tablet ?? regular;
    }

    return isCompactWidth(context) ? compact : regular;
  }

  /// Devuelve el margen horizontal recomendado para layouts cliente.
  static double responsiveScreenMargin(BuildContext context) {
    return responsiveDouble(
      context,
      compact: spacingMd,
      regular: spacingScreen,
      tablet: spacingLg,
    );
  }

  /// Devuelve el color de fondo adecuado para las pantallas de autenticación.
  static Color authBackgroundColor(BuildContext context) {
    return isDark(context) ? authBackground : white;
  }

  /// Devuelve el color de relleno de los inputs de autenticación.
  static Color authInputFillColor(BuildContext context) {
    return isDark(context) ? authFieldBackground : customerLightSurface;
  }

  /// Devuelve el color principal de texto para login, registro y recovery.
  static Color authTextColor(BuildContext context) {
    return isDark(context) ? authFieldText : secondary;
  }

  /// Devuelve el color para placeholders y textos de ayuda en auth.
  static Color authHintColor(BuildContext context) {
    return isDark(context) ? authPlaceholder : gray;
  }

  /// Devuelve el color de bordes usado en botones sociales y campos auth.
  static Color authOutlineColor(BuildContext context) {
    return isDark(context) ? authSocialBorder : border;
  }

  // Escala de espaciados estándar para paddings, gaps y layouts.
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingSmd = 12;
  static const double spacingMd = 16;
  static const double spacingScreen = 20;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Márgenes recomendados para pantallas, cards y modales.
  static const double screenMargin = spacingScreen;
  static const double cardMargin = spacingMd;
  static const double modalMargin = spacingLg;

  // Radios de borde por tipo de componente.
  static const double radiusChip = 8;
  static const double radiusInput = 12;
  static const double radiusCard = 16;
  static const double radiusModal = 24;
  static const double radiusButton = 16;

  // Alias cortos para radios comunes.
  static const double radiusSm = radiusChip;
  static const double radiusMd = radiusCard;
  static const double radiusLg = radiusModal;

  // Tamaños base para iconografía.
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // Estilo para títulos principales de mayor jerarquía.
  static const TextStyle display = TextStyle(
    fontFamily: primaryFont,
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  // Estilo para títulos H1 de pantallas y secciones principales.
  static const TextStyle h1 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  // Estilo para subtítulos grandes o encabezados secundarios.
  static const TextStyle h2 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: secondary,
  );

  // Estilo para títulos de cards, botones grandes o bloques destacados.
  static const TextStyle h3 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: secondary,
  );

  // Estilo para texto de lectura con énfasis moderado.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: secondary,
  );

  // Estilo base para textos normales de la interfaz.
  static const TextStyle body = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondary,
  );

  // Estilo para ayudas, descripciones cortas y textos secundarios.
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: gray,
  );

  // Estilo para etiquetas pequeñas, chips y metadatos.
  static const TextStyle label = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: secondary,
  );

  // Botón principal para acciones de mayor importancia.
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  // Botón secundario con borde para acciones alternativas.
  static final ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primary,
    minimumSize: const Size(double.infinity, 56),
    side: const BorderSide(color: primary, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  // Botón sin fondo para acciones de bajo peso visual.
  static final ButtonStyle ghostButton = TextButton.styleFrom(
    foregroundColor: primary,
    minimumSize: const Size(0, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  /// Construye una decoración estándar para campos de texto.
  ///
  /// Permite reutilizar el mismo borde, padding, colores y estados de foco/error.
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? white : background,
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: border),
      ),
      contentPadding: const EdgeInsets.all(spacingMd),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: error, width: 2),
      ),
    );
  }

  // Sombra suave para cards o elementos con elevación mínima.
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Sombra media para componentes más destacados.
  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Sombra alta para overlays, modales o elementos flotantes.
  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Decoración base para cards blancas con radio y sombra.
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusCard),
    boxShadow: shadowLevel1,
  );

  /// Tema claro global del módulo cliente.
  static ThemeData get lightTheme => _themeData(Brightness.light);

  /// Tema oscuro global del módulo cliente.
  static ThemeData get darkTheme => _themeData(Brightness.dark);

  /// Construye el ThemeData compartido para modo claro u oscuro.
  static ThemeData _themeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Colores derivados según el modo actual.
    final surfaceColor = isDark ? darkSurface : customerLightSurface;
    final backgroundColor = isDark ? darkBackground : customerLightBackground;
    final textColor = isDark ? darkText : customerLightText;
    final secondaryTextColor = isDark
        ? darkSecondaryText
        : customerLightSecondaryText;
    final borderColor = isDark ? gray : customerLightDivider;

    // ColorScheme usado por componentes Material.
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: primary,
            onPrimary: white,
            secondary: gray,
            onSecondary: secondary,
            surface: darkSurface,
            onSurface: white,
            error: error,
            onError: white,
            outline: gray,
          )
        : const ColorScheme.light(
            primary: primary,
            onPrimary: white,
            secondary: secondary,
            onSecondary: white,
            surface: customerLightSurface,
            onSurface: customerLightText,
            error: error,
            onError: white,
            outline: customerLightDivider,
          );

    // TextTheme global construido desde los estilos de AutolabCustomer.
    final textTheme = TextTheme(
      displayLarge: display.copyWith(color: textColor),
      headlineLarge: h1.copyWith(color: textColor),
      headlineMedium: h2.copyWith(color: textColor),
      headlineSmall: h3.copyWith(color: textColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: body.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: secondaryTextColor),
      labelLarge: label.copyWith(color: textColor),
    );

    // ThemeData final que consume MaterialApp.
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: primaryFont,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: colorScheme,
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.all(spacingMd),
        border: _inputBorder(borderColor),
        enabledBorder: _inputBorder(borderColor),
        disabledBorder: _inputBorder(borderColor),
        focusedBorder: _inputBorder(primary, width: 2),
        errorBorder: _inputBorder(error),
        focusedErrorBorder: _inputBorder(error, width: 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: shadowLevel1.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      extensions: [
        AutolabCustomColors(
          success: success,
          warning: warning,
          info: info,
          appointmentConfirmed: appointmentConfirmed,
          appointmentPending: appointmentPending,
          appointmentCancelled: appointmentCancelled,
          appointmentCompleted: isDark ? white : appointmentCompleted,
          navigationActive: navigationActive,
          navigationInactive: navigationInactive,
          ratingBadge: ratingBadge,
          distanceBadge: isDark ? darkSurface : distanceBadge,
        ),
      ],
    );
  }

  /// Crea un borde estándar para inputs con radio y color configurables.
  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusInput),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

@immutable
/// Extensión del tema para colores propios que no existen en ColorScheme.
class AutolabCustomColors extends ThemeExtension<AutolabCustomColors> {
  const AutolabCustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.appointmentConfirmed,
    required this.appointmentPending,
    required this.appointmentCancelled,
    required this.appointmentCompleted,
    required this.navigationActive,
    required this.navigationInactive,
    required this.ratingBadge,
    required this.distanceBadge,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color appointmentConfirmed;
  final Color appointmentPending;
  final Color appointmentCancelled;
  final Color appointmentCompleted;
  final Color navigationActive;
  final Color navigationInactive;
  final Color ratingBadge;
  final Color distanceBadge;

  /// Crea una copia de la extensión cambiando solo los valores necesarios.
  @override
  AutolabCustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? appointmentConfirmed,
    Color? appointmentPending,
    Color? appointmentCancelled,
    Color? appointmentCompleted,
    Color? navigationActive,
    Color? navigationInactive,
    Color? ratingBadge,
    Color? distanceBadge,
  }) {
    return AutolabCustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      appointmentConfirmed: appointmentConfirmed ?? this.appointmentConfirmed,
      appointmentPending: appointmentPending ?? this.appointmentPending,
      appointmentCancelled: appointmentCancelled ?? this.appointmentCancelled,
      appointmentCompleted: appointmentCompleted ?? this.appointmentCompleted,
      navigationActive: navigationActive ?? this.navigationActive,
      navigationInactive: navigationInactive ?? this.navigationInactive,
      ratingBadge: ratingBadge ?? this.ratingBadge,
      distanceBadge: distanceBadge ?? this.distanceBadge,
    );
  }

  /// Interpola colores cuando Flutter anima cambios de tema.
  @override
  AutolabCustomColors lerp(covariant AutolabCustomColors? other, double t) {
    if (other == null) {
      return this;
    }

    return AutolabCustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      appointmentConfirmed: Color.lerp(
        appointmentConfirmed,
        other.appointmentConfirmed,
        t,
      )!,
      appointmentPending: Color.lerp(
        appointmentPending,
        other.appointmentPending,
        t,
      )!,
      appointmentCancelled: Color.lerp(
        appointmentCancelled,
        other.appointmentCancelled,
        t,
      )!,
      appointmentCompleted: Color.lerp(
        appointmentCompleted,
        other.appointmentCompleted,
        t,
      )!,
      navigationActive: Color.lerp(
        navigationActive,
        other.navigationActive,
        t,
      )!,
      navigationInactive: Color.lerp(
        navigationInactive,
        other.navigationInactive,
        t,
      )!,
      ratingBadge: Color.lerp(ratingBadge, other.ratingBadge, t)!,
      distanceBadge: Color.lerp(distanceBadge, other.distanceBadge, t)!,
    );
  }
}
