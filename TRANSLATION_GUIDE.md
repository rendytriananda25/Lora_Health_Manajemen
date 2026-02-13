# Lora Multi-Language Support (i18n) Guide

## 📝 Overview
This document provides guidance on using the translation files for Lora's multi-language support.

## 🌍 Supported Languages
- **Indonesian** (id.json) - Default language
- **English** (en.json) - American English
- **Japanese** (ja.json) - 日本語
- **Spanish** (es.json) - Español (España)

## 📂 File Structure
```
assets/
└── i18n/
    ├── id.json     (Indonesian)
    ├── en.json     (English)
    ├── ja.json     (Japanese)
    └── es.json     (Spanish)
```

## 🔧 How to Use in Flutter

### 1. Add pubspec.yaml Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: ^0.18.0  # For Localization
```

### 2. Create a Translation Helper Class
```dart
// lib/core/services/translation_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  
  factory TranslationService() {
    return _instance;
  }
  
  TranslationService._internal();
  
  late Map<String, dynamic> _translations;
  String _currentLanguage = 'id'; // Default: Indonesian
  
  Future<void> initialize(String languageCode) async {
    _currentLanguage = languageCode;
    await loadTranslations(languageCode);
  }
  
  Future<void> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
      _translations = json.decode(jsonString);
    } catch (e) {
      print('Error loading translations: $e');
      // Fallback to Indonesian
      final jsonString = await rootBundle.loadString('assets/i18n/id.json');
      _translations = json.decode(jsonString);
    }
  }
  
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
    
    return value.toString();
  }
  
  String get currentLanguage => _currentLanguage;
  
  List<String> get supportedLanguages => ['id', 'en', 'ja', 'es'];
}
```

### 3. Use in Your Widgets
```dart
// Example in Login Screen
import 'package:lora_1/core/services/translation_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _translationService = TranslationService();
  
  @override
  void initState() {
    super.initState();
    // Initialize with saved language or default
    _translationService.initialize('id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(
            _translationService.translate('auth.welcome'),
            // Output: "Selamat datang di Lora" (ID)
            // Output: "Welcome to Lora" (EN)
          ),
          Text(
            _translationService.translate('auth.welcomeDesc'),
          ),
        ],
      ),
    );
  }
}
```

### 4. Language Switch Implementation
```dart
// In Settings or Language Selection Screen
class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final _translationService = TranslationService();
  late String _selectedLanguage;
  
  @override
  void initState() {
    super.initState();
    _selectedLanguage = _translationService.currentLanguage;
  }

  void _changeLanguage(String languageCode) async {
    await _translationService.initialize(languageCode);
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_translationService.translate('settings.language'))),
      body: ListView(
        children: [
          _buildLanguageOption('id', 'Bahasa Indonesia', 'Indonesian'),
          _buildLanguageOption('en', 'English', 'English (US)'),
          _buildLanguageOption('ja', '日本語', 'Japanese'),
          _buildLanguageOption('es', 'Español', 'Spanish'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String nativeName, String englishName) {
    return ListTile(
      title: Text(nativeName),
      subtitle: Text(englishName),
      trailing: _selectedLanguage == code
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () => _changeLanguage(code),
    );
  }
}
```

### 5. Initialize Language on App Start
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase, etc.
  
  // Load saved language preference
  final prefs = await SharedPreferences.getInstance();
  String savedLanguage = prefs.getString('selected_language') ?? 'id';
  
  final translationService = TranslationService();
  await translationService.initialize(savedLanguage);
  
  runApp(const MyApp());
}
```

## 📋 Translation Key Structure

Each translation file follows this structure:
```json
{
  "section": {
    "key": "translation text"
  }
}
```

### Available Sections:
- **app** - Application name and info
- **auth** - Authentication-related strings
- **dashboard** - Dashboard page strings
- **weather** - Weather-related messages
- **fitness** - Fitness goal messages
- **nutrition** - Nutrition-related strings
- **settings** - Settings page strings
- **navigation** - Navigation labels
- **sports** - Sports-related strings
- **errors** - Error messages
- **messages** - Common UI messages

## 🔄 Extension Guide

To add new translations:

1. Add the key-value pair to all 4 language files in the same structure
2. Use the format: `section.key` when calling `translate()`

Example:
```json
// New section in all files
{
  "newFeature": {
    "title": "..."
  }
}
```

Then use:
```dart
_translationService.translate('newFeature.title')
```

## 🐛 Troubleshooting

- **Missing translations**: Check JSON file format and key paths
- **File not found**: Ensure i18n folder exists in assets directory
- **Fallback to Indonesian**: Add to pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/i18n/
```

## 📞 Language Codes
- `id` - Indonesian
- `en` - English (American)
- `ja` - Japanese
- `es` - Spanish (Spain)

## ✅ Best Practices

1. Always provide translations in all 4 languages
2. Keep translation keys consistent across files
3. Use namespacing (section.key) for organization
4. Test with all languages before deployment
5. Save user's language preference to SharedPreferences
6. Load saved language on app startup

