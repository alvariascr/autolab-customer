import 'package:flutter/material.dart';

class AutolabCustomer {
  const AutolabCustomer._();

  // Font families
  static const String primaryFont = 'Poppins';

  // Colors
  static const Color primary = Color(0xFFFF281B);
  static const Color secondary = Color(0xFF000000);

  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFA9A9A9);
  static const Color background = Color(0xFFF4E9E9);
  static const Color border = Color(0xFFE5E5E5);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Appointment statuses
  static const Color appointmentConfirmed = success;
  static const Color appointmentPending = warning;
  static const Color appointmentCancelled = error;
  static const Color appointmentCompleted = secondary;

  // Navigation and badges
  static const Color navigationActive = primary;
  static const Color navigationInactive = gray;
  static const Color ratingBadge = success;
  static const Color distanceBadge = background;

  // Dark mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = white;
  static const Color darkSecondaryText = gray;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingSmd = 12;
  static const double spacingMd = 16;
  static const double spacingScreen = 20;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Margins
  static const double screenMargin = spacingScreen;
  static const double cardMargin = spacingMd;
  static const double modalMargin = spacingLg;

  // Border radius
  static const double radiusChip = 8;
  static const double radiusInput = 12;
  static const double radiusCard = 16;
  static const double radiusModal = 24;
  static const double radiusButton = 16;

  static const double radiusSm = radiusChip;
  static const double radiusMd = radiusCard;
  static const double radiusLg = radiusModal;

  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // Text styles
  static const TextStyle display = TextStyle(
    fontFamily: primaryFont,
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: secondary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: secondary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: secondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: gray,
  );

  static const TextStyle label = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: secondary,
  );

  // Buttons
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  static final ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primary,
    minimumSize: const Size(double.infinity, 56),
    side: const BorderSide(color: primary, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  static final ButtonStyle ghostButton = TextButton.styleFrom(
    foregroundColor: primary,
    minimumSize: const Size(0, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
  );

  // Input decoration
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

  // Shadows
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Card decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusCard),
    boxShadow: shadowLevel1,
  );

  static ThemeData get lightTheme => _themeData(Brightness.light);

  static ThemeData get darkTheme => _themeData(Brightness.dark);

  static ThemeData _themeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? darkSurface : white;
    final backgroundColor = isDark ? darkBackground : background;
    final textColor = isDark ? darkText : secondary;
    final secondaryTextColor = isDark ? darkSecondaryText : gray;
    final borderColor = isDark ? gray : border;

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
            surface: white,
            onSurface: secondary,
            error: error,
            onError: white,
            outline: border,
          );

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

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusInput),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

@immutable
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
