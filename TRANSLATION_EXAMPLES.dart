// 📝 Example: How to Use Translations in Your Screens

// ============================================
// 1️⃣ SIMPLE WAY - Use Consumer Widget
// ============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/translation_service.dart';

class LoginScreenExample extends StatelessWidget {
  const LoginScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  languageProvider.translate('auth.welcome'),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            
                ),
                const SizedBox(height: 10),
                Text(
                  languageProvider.translate('auth.welcomeDesc'),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    hintText: languageProvider.translate('auth.email'),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: languageProvider.translate('auth.password'),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(languageProvider.translate('auth.loginButton')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// 2️⃣ WITH STATE - Stateful Widget approach
// ============================================
class DashboardScreenExample extends StatefulWidget {
  const DashboardScreenExample({super.key});

  @override
  State<DashboardScreenExample> createState() => _DashboardScreenExampleState();
}

class _DashboardScreenExampleState extends State<DashboardScreenExample> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('dashboard.lora')),
      ),
      body: Column(
        children: [
          Text(
            languageProvider.translate('dashboard.hello'),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  const Icon(Icons.air),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(languageProvider.translate('dashboard.airQuality')),
                      Text(languageProvider.translate('dashboard.good')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 3️⃣ PERFORMANCE - Only watch language changes
// ============================================
class SettingsScreenExample extends StatelessWidget {
  const SettingsScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Only watch when language changes
    final currentLanguage = context.watch<LanguageProvider>().currentLanguage;
    
    // Get translate function (doesn't rebuild on every translate call)
    final translate = context.read<LanguageProvider>().translate;

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('settings.settings')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(translate('settings.personalInfo')),
            trailing: const Icon(Icons.arrow_forward),
          ),
          ListTile(
            title: Text(translate('settings.security')),
            trailing: const Icon(Icons.arrow_forward),
          ),
          ListTile(
            title: Text(translate('settings.notifications')),
            trailing: const Icon(Icons.arrow_forward),
          ),
          ListTile(
            title: Text(translate('settings.language')),
            subtitle: Text('Current: $currentLanguage'),
            trailing: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 4️⃣ USING IN PROVIDER LOGIC
// ============================================

class SomeBusinessLogic {
  final TranslationService _translationService = TranslationService();

  void handleSomething() {
    String message = _translationService.translate('messages.success');
    print(message);
    
    // Or use from LanguageProvider
    // final provider = context.read<LanguageProvider>();
    // String msg = provider.translate('errors.loginFailed');
  }
}

// ============================================
// 5️⃣ CHANGE LANGUAGE FROM ANYWHERE
// ============================================
class LanguageSwitcherExample extends StatelessWidget {
  const LanguageSwitcherExample({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () async {
            // ✅ Change to Indonesian
            await languageProvider.changeLanguage('id');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changed to Indonesian')),
              );
            }
          },
          child: const Text('🇮🇩 ID'),
        ),
        ElevatedButton(
          onPressed: () async {
            // ✅ Change to English
            await languageProvider.changeLanguage('en');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changed to English')),
              );
            }
          },
          child: const Text('🇺🇸 EN'),
        ),
        ElevatedButton(
          onPressed: () async {
            // ✅ Change to Japanese
            await languageProvider.changeLanguage('ja');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changed to Japanese')),
              );
            }
          },
          child: const Text('🇯🇵 JA'),
        ),
        ElevatedButton(
          onPressed: () async {
            // ✅ Change to Spanish
            await languageProvider.changeLanguage('es');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changed to Spanish')),
              );
            }
          },
          child: const Text('🇪🇸 ES'),
        ),
      ],
    );
  }
}

// ============================================
// 6️⃣ TIPS & TRICKS
// ============================================

// ✅ Get current language (INSIDE a widget or function with BuildContext):
// String currentLang = context.read<LanguageProvider>().currentLanguage;

// ✅ Get language name (INSIDE a widget or function):
// String langName = context.read<LanguageProvider>().getLanguageName('id');
// Output: "Bahasa Indonesia"

// ✅ Get all supported languages (INSIDE a widget or function):
// List<String> langs = context.read<LanguageProvider>().getSupportedLanguages();
// Output: ['id', 'en', 'ja', 'es']

// ✅ Direct access to TranslationService (if needed, INSIDE a widget or function):
// var service = context.read<LanguageProvider>().translationService;
// String translated = service.translate('auth.welcome'); // 'service' harus didefinisikan di dalam widget/fungsi

// ✅ Format translations with variables (extend service if needed)
// String greeting = languageProvider.translate('dashboard.hello', {'name': 'John'});
// For this, extend TranslationService.translate() to support parameters
