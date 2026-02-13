# 🌍 Language Switching Implementation Guide

## ✅ Completed Setup

### 1. Translation Service Created
- **File**: `lib/core/services/translation_service.dart`
- Loads JSON translations from `assets/i18n/`
- Supports: Indonesian (id), English (en), Japanese (ja), Spanish (es)

### 2. Language Provider Created  
- **File**: `lib/core/services/language_provider.dart`
- Manages current language state
- Persists language choice to SharedPreferences
- Notifies listeners when language changes

### 3. Language Page Updated
- **File**: `lib/features/settings/language_page.dart`
- Shows all 4 languages with flags
- User can tap to change language
- Changes are persisted automatically

---

## ⚙️ Integration Steps

### Step 1: Update `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.2.0
  shared_preferences: ^2.2.0

flutter:
  assets:
    - assets/i18n/
```

### Step 2: Initialize in `main.dart`
```dart
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize language provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => languageProvider),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lora',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF008BFF),
      ),
      home: const OnboardingScreen(), // Or your entry point
    );
  }
}
```

### Step 3: Use in Widgets - Simple Way

```dart
// Example: Login Screen
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          body: Column(
            children: [
              Text(
                languageProvider.translate('auth.welcome'),
                // ID: "Selamat datang di Lora"
                // EN: "Welcome to Lora"
                // JA: "ローラへようこそ"
                // ES: "Bienvenido a Lora"
              ),
              Text(languageProvider.translate('auth.welcomeDesc')),
            ],
          ),
        );
      },
    );
  }
}
```

### Step 4: Use in Widgets - Advanced Way (with watch)

```dart
// For performance: Use when only specific translations change
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch only for language changes
    final language = context.watch<LanguageProvider>().currentLanguage;
    final translate = context.read<LanguageProvider>().translate;

    return Container(
      child: Text(
        translate('dashboard.hello'),
      ),
    );
  }
}
```

---

## 🎯 Usage Examples

### In Login Screen
```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();

    return Scaffold(
      body: Column(
        children: [
          Text(languageProvider.translate('auth.welcome')),
          TextField(
            hint: languageProvider.translate('auth.email'),
          ),
          TextField(
            hint: languageProvider.translate('auth.password'),
          ),
          ElevatedButton(
            onPressed: () {
              // Login logic
            },
            child: Text(languageProvider.translate('auth.loginButton')),
          ),
        ],
      ),
    );
  }
}
```

### In Dashboard
```dart
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.translate('dashboard.lora')),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text(languageProvider.translate('dashboard.hello')),
                Text(languageProvider.translate('dashboard.status')),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### In Settings
```dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.translate('settings.settings')),
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(languageProvider.translate('settings.personalInfo')),
              ),
              ListTile(
                title: Text(languageProvider.translate('settings.language')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LanguagePage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 📋 Translation Keys Available

### Auth Keys
```
auth.welcome
auth.welcomeDesc
auth.email
auth.password
auth.confirmPassword
auth.fullName
auth.emailAddress
auth.loginButton
auth.signUpButton
auth.signUp
auth.haveAccount
auth.allFieldsRequired
```

### Dashboard Keys
```
dashboard.hello
dashboard.loadingLocation
dashboard.connectionFailed
dashboard.analyzing
dashboard.lora
dashboard.status
dashboard.airQuality
dashboard.uvIndex
```

### Settings Keys
```
settings.settings
settings.personalInfo
settings.security
settings.notifications
settings.language
settings.logout
```

*For complete list, check: `assets/i18n/id.json`*

---

## 🔄 How Language Switching Works

```
User taps language in LanguagePage
        ↓
LanguageProvider.changeLanguage() called
        ↓
TranslationService loads new JSON file
        ↓
Language saved to SharedPreferences
        ↓
ChangeNotifier notifies all listeners
        ↓
Widgets rebuild with new translations
```

---

## 🚀 Quick Implementation Checklist

- [ ] Add `provider` to pubspec.yaml
- [ ] Add `shared_preferences` to pubspec.yaml
- [ ] Add assets to pubspec.yaml (`assets/i18n/`)
- [ ] Run `flutter pub get`
- [ ] Copy TranslationService to `lib/core/services/`
- [ ] Copy LanguageProvider to `lib/core/services/`
- [ ] Update main.dart with Provider setup
- [ ] Replace hardcoded strings with `languageProvider.translate()`
- [ ] Test language switching in LanguagePage

---

## ⚡ Performance Tips

1. **Use `Consumer` for specific widgets**: Only rebuild the widget that needs translation
2. **Use `context.read()` for one-time access**: No need to rebuild
3. **Cache translations**: TranslationService already does this
4. **Lazy load**: Translations loaded only when language changes

---

## 🧪 Testing

```dart
// Test in language_page.dart
void main() {
  group('Language Provider Tests', () {
    test('Should change language', () async {
      final provider = LanguageProvider();
      await provider.initialize();
      
      await provider.changeLanguage('en');
      expect(provider.currentLanguage, 'en');
      
      expect(
        provider.translate('auth.welcome'),
        'Welcome to Lora',
      );
    });
  });
}
```

---

## 📞 Support

If language not changing:
1. Check `pubspec.yaml` has `provider` dependency
2. Check `main.dart` has `MultiProvider` wrapper
3. Check `assets/i18n/` files exist
4. Check console logs for translation errors

