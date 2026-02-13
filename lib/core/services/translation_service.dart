import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() {
    return _instance;
  }

  TranslationService._internal();

  late Map<String, dynamic> _translations = {};
  String _currentLanguage = 'id'; // Default: Indonesian

  /// Initialize with a specific language
  Future<void> initialize(String languageCode) async {
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  /// Change language at runtime
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  /// Load translation file from assets
  Future<void> _loadTranslations(String languageCode) async {
    try {
      // Map language code: 'jp' → 'ja' (if needed)
      String fileCode = languageCode;
      if (languageCode == 'jp') {
        fileCode = 'ja';
      }

      final jsonString = await rootBundle.loadString('assets/i18n/$fileCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ Loaded translations for: $languageCode');
    } catch (e) {
      print('❌ Error loading translations: $e');
      // Fallback to Indonesian
      try {
        final jsonString = await rootBundle.loadString('assets/i18n/id.json');
        _translations = json.decode(jsonString) as Map<String, dynamic>;
        _currentLanguage = 'id';
        print('⚠️ Fallback to Indonesian');
      } catch (fallbackError) {
        print('❌ Critical error: $fallbackError');
        _translations = {};
      }
    }
  }

  /// Translate key with dot notation (e.g., 'auth.welcome')
  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _translations;

    for (String k in keys) {
      if (value is Map) {
        value = value[k];
      } else {
        return key; // Return key if path not found
      }
    }

    return value?.toString() ?? key;
  }

  /// Get current language code
  String get currentLanguage => _currentLanguage;

  /// Get supported languages
  List<String> get supportedLanguages => ['id', 'en', 'ja', 'es'];

  /// Get language name in its native language
  String getLanguageName(String code) {
    Map<String, String> names = {
      'id': 'Bahasa Indonesia',
      'en': 'English',
      'ja': '日本語',
      'es': 'Español',
    };
    return names[code] ?? code;
  }

  /// Clear translations (for testing)
  void clear() {
    _translations = {};
    _currentLanguage = 'id';
  }
}
