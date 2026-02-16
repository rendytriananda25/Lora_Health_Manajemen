import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default Dark

  bool get isDarkMode => _isDarkMode;

  // 🔥 CUSTOM COLORS
  // Dark Mode
  static const Color darkBg = Colors.black;
  static const Color darkBox = Color(0xFF141416);
  static const Color darkText = Colors.white;
  static const Color darkSubText = Colors.white54;
  static const Color darkBorder = Colors.white10;

  // Light Mode (Sesuai Request: Putih Butek & Putih Bersih)
  static const Color lightBg = Color(0xFFF5F5F5); // Putih Butek
  static const Color lightBox = Colors.white; // Putih Bersih
  static const Color lightText = Colors.black;
  static const Color lightSubText = Colors.black54;
  static const Color lightBorder = Colors.black12;

  // Colors Accessor
  Color get bgColor => _isDarkMode ? darkBg : lightBg;
  Color get boxColor => _isDarkMode ? darkBox : lightBox;
  Color get textColor => _isDarkMode ? darkText : lightText;
  Color get subTextColor => _isDarkMode ? darkSubText : lightSubText;
  Color get borderColor => _isDarkMode ? darkBorder : lightBorder;

  // Specific for Logout Button
  Color get logoutBtnBg => _isDarkMode
      ? const Color.fromARGB(255, 255, 0, 0).withOpacity(0.1)
      : Colors.red; // Solid Red for Light Mode

  Color get logoutBtnText => _isDarkMode
      ? const Color.fromARGB(255, 255, 0, 0)
      : Colors.white; // White for Light Mode

  // Initialize (Load from Prefs)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default Dark
    notifyListeners();
  }

  // Toggle Theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // ThemeData (If using Material Theme)
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bgColor,
    cardColor: boxColor,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
    ),
    iconTheme: IconThemeData(color: textColor),
    appBarTheme: AppBarTheme(
      backgroundColor: bgColor,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textColor),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF008BFF),
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      background: bgColor,
    ).copyWith(background: bgColor),
  );
}
