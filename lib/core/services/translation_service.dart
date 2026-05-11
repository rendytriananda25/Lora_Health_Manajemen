import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() {
    return _instance;
  }

  TranslationService._internal();

  late Map<String, dynamic> _translations = {};
  String _currentLanguage = 'id';

  Future<void> initialize(String languageCode) async {
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  Future<void> _loadTranslations(String languageCode) async {
    try {
      String fileCode = languageCode;
      if (languageCode == 'jp') {
        fileCode = 'ja';
      }

      final jsonString = await rootBundle.loadString('assets/i18n/$fileCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ Loaded translations for: $languageCode');
    } catch (e) {
      print('❌ Error loading translations: $e');
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

  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _translations;

    for (String k in keys) {
      if (value is Map) {
        value = value[k];
      } else {
        return key;
      }
    }

    return value?.toString() ?? key;
  }

  String get currentLanguage => _currentLanguage;

  List<String> get supportedLanguages => ['id', 'en', 'ja', 'es'];

  String getLanguageName(String code) {
    Map<String, String> names = {
      'id': 'Bahasa Indonesia',
      'en': 'English',
      'ja': '日本語',
      'es': 'Español',
    };
    return names[code] ?? code;
  }

  void clear() {
    _translations = {};
    _currentLanguage = 'id';
  }
}
