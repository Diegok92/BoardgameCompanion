import 'package:flutter/material.dart';

class AppColors {
  static const Color red = Color(0xFFE53935);
  static const Color orange = Color(0xFFFB8C00);
  static const Color yellow = Color(0xFFFDD835);
  static const Color green = Color(0xFF43A047);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color blue = Color(0xFF1E88E5);
  static const Color purple = Color(0xFF8E24AA);
  static const Color pink = Color(0xFFD81B60);
  static const Color brown = Color(0xFF6D4C41);
  static const Color grey = Color(0xFF607D8B);

  // para accesorios (fondo claro de tarjeta)
  static const Color lightOrange = Color(0xFFFFF3D6);
  static const Color lightRed = Color(0xFFEF9A9A);

  // Colores semánticos del Truco: las "malas" (naranja) y las "buenas" (verde).
  static const Color trucoMalas = Color(0xFFFF8A1C);
  static const Color trucoBuenas = Color(0xFF16A85A);

  static const List<Color> availableColors = [
    red,
    orange,
    yellow,
    green,
    cyan,
    blue,
    purple,
    pink,
    brown,
    grey,
  ];

  /// Devuelve negro o blanco según cuál tenga mejor contraste sobre [background].
  /// Útil para que el texto se lea bien sobre cualquier color de jugador.
  static Color contrastOn(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
