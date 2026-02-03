import 'package:flutter/material.dart';

/// Paleta de colores Ocean Sunset
class AppColors {
  // Colores principales
  static const Color deepBlue = Color(0xFF001219);
  static const Color tealBlue = Color(0xFF005F73);
  static const Color turquoise = Color(0xFF0A9396);
  static const Color aquaGreen = Color(0xFF94D2BD);
  static const Color warmBeige = Color(0xFFE9D8A6);
  static const Color goldenYellow = Color(0xFFEE9B00);
  static const Color orange = Color(0xFFCA6702);
  static const Color redOrange = Color(0xFFBB3E03);
  static const Color red = Color(0xFFAE2012);
  static const Color garnet = Color(0xFF9B2226);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [tealBlue, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [goldenYellow, orange, redOrange],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [deepBlue, tealBlue, turquoise],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [turquoise, aquaGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [goldenYellow, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [redOrange, red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Colores de estado
  static const Color success = turquoise;
  static const Color warning = goldenYellow;
  static const Color error = red;
  static const Color info = tealBlue;
  
  // Colores de fondo
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color shadowColor = Color(0x1A000000);
  
  // Colores de texto
  static const Color textPrimary = deepBlue;
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);
  static const Color textOnDark = Colors.white;
}

/// Variantes de color (reemplazo de withOpacity y shadeXXX)
extension AppColorVariants on Color {
  // Opacidades bajas (fondos suaves)
  Color o05() => withValues(alpha: 13);   // 0.05
  Color o10() => withValues(alpha: 26);   // 0.10
  Color o20() => withValues(alpha: 51);   // 0.20
  Color o30() => withValues(alpha: 77);   // 0.30

  // Opacidades medias (bordes / overlays)
  Color o40() => withValues(alpha: 102);  // 0.40
  Color o50() => withValues(alpha: 128);  // 0.50
  Color o60() => withValues(alpha: 153);  // 0.60

  // Opacidades altas (texto / énfasis)
  Color o70() => withValues(alpha: 179);  // 0.70
  Color shade800() => withValues(alpha: 200); //0.785
  Color o80() => withValues(alpha: 204);  // 0.80
  Color o90() => withValues(alpha: 230);  // 0.90
  Color o100() => withValues(alpha: 255); // 1.00
}
