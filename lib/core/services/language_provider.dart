import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';

class LanguageProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  String _currentLanguage = 'id';

  String get currentLanguage => _currentLanguage;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    String savedLanguage = prefs.getString('app_language') ?? 'id';

    await _translationService.initialize(savedLanguage);
    _currentLanguage = savedLanguage;
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      await _translationService.changeLanguage(languageCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);

      _currentLanguage = languageCode;
      notifyListeners();
      print('✅ Language changed to: $languageCode');
    } catch (e) {
      print('❌ Error changing language: $e');
    }
  }

  String translate(String key) {
    return _translationService.translate(key);
  }

  String getLanguageName(String code) {
    return _translationService.getLanguageName(code);
  }

  List<String> getSupportedLanguages() {
    return _translationService.supportedLanguages;
  }

  TranslationService get translationService => _translationService;
}
