import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryColorLight = Color(0xFF42A5F5);
  static const Color primaryColorDark = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF03A9F4);
  
  // Cores de texto
  static const Color textColor = Colors.black;
  static const Color textColorLight = Colors.black54;
  
  // Cores de fundo
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color scaffoldBackgroundColor = Colors.white;
  
  // Cores de estado
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.amber;
  
  // Sombra padrão
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // TextStyles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textColor,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textColor,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textColorLight,
  );
  
  // Decoração padrão para input
  static InputDecoration inputDecoration(String label, {String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColorLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
  
  // Botão padrão
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primaryColor),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevation: MaterialStateProperty.all(2),
  );
  
  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primaryColorLight.withOpacity(0.3), width: 1),
    boxShadow: defaultShadow,
  );
  
  // Tema para o MaterialApp
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    primaryColorLight: primaryColorLight,
    primaryColorDark: primaryColorDark,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.black12,
      thickness: 1,
    ),
  );
}