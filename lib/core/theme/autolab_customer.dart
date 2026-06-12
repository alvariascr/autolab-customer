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
        borderSide: BorderSide.none,
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
}
