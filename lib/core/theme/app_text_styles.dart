import 'package:flutter/material.dart';

class AppTextStyles {
  static const roboto = 'Roboto';

  // TITULOS PRINCIPAL 1
  static const titleWaxcel = TextStyle(
    fontFamily: 'Waxcel',
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // TITULOS PRINCIPAL 2
  static const title = TextStyle(
    fontFamily: roboto,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // SUBTITULOS
  static const subtitle = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // TEXTO NORMAL
  static const normal = TextStyle(fontFamily: roboto, fontSize: 14);

  // TEXTO PEQUEÑO
  static const small = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    color: Colors.grey,
  );
}
