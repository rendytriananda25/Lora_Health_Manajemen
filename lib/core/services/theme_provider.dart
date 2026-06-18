import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;


  static const Color darkBg = Colors.black;
  static const Color darkBox = Color(0xFF141416);
  static const Color darkText = Colors.white;
  static const Color darkSubText = Colors.white54;
  static const Color darkBorder = Colors.white10;


  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightBox = Colors.white;
  static const Color lightText = Colors.black;
  static const Color lightSubText = Colors.black54;
  static const Color lightBorder = Colors.black12;


  Color get bgColor => _isDarkMode ? darkBg : lightBg;
  Color get boxColor => _isDarkMode ? darkBox : lightBox;
  Color get textColor => _isDarkMode ? darkText : lightText;
  Color get subTextColor => _isDarkMode ? darkSubText : lightSubText;
  Color get borderColor => _isDarkMode ? darkBorder : lightBorder;


  Color get logoutBtnBg => _isDarkMode
      ? const Color.fromARGB(255, 255, 0, 0).withOpacity(0.1)
      : Colors.red;

  Color get logoutBtnText => _isDarkMode
      ? const Color.fromARGB(255, 255, 0, 0)
      : Colors.white;


  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    debugPrint("🎨 Theme Loaded: ${_isDarkMode ? 'Dark' : 'Light'}");
    notifyListeners();
  }


  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    debugPrint("🎨 Theme Saved: ${_isDarkMode ? 'Dark' : 'Light'}");
    notifyListeners();
  }


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
