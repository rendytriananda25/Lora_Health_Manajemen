import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'widgets/setting_widgets.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});
  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  // List ini tetap begini karena nama bahasa tidak perlu diterjemahkan
  final List<Map<String, String>> languages = [
    {"name": "Bahasa Indonesia", "code": "id", "flag": "🇮🇩"},
    {"name": "English", "code": "en", "flag": "🇺🇸"},
    {"name": "日本語 (Japanese)", "code": "ja", "flag": "🇯🇵"},
    {"name": "Español", "code": "es", "flag": "🇪🇸"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header sekarang pakai teks dinamis (opsional jika sudah ada di JSON)
            const SettingHeader(title: "Language"),
            Expanded(
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      String languageCode = languages[index]['code']!;
                      bool isSelected = languageProvider.currentLanguage == languageCode;

                      return GestureDetector(
                        onTap: () async {
                          // ✅ Proses ganti bahasa global lewat Provider
                          await languageProvider.changeLanguage(languageCode);

                          if (mounted) {
                            // ✅ Feedback SnackBar (Pesan diambil berdasarkan bahasa baru)
                            String feedbackMsg = languageCode == 'id' 
                                ? 'Bahasa berhasil diubah' 
                                : 'Language changed successfully';
                                
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(feedbackMsg, style: const TextStyle(color: Colors.white)),
                                backgroundColor: const Color(0xFF008BFF),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF008BFF).withOpacity(0.15)
                                : const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF008BFF)
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      languages[index]['flag']!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      languages[index]['name']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ✅ Indicator Checklist
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF008BFF) : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  color: isSelected ? const Color(0xFF008BFF) : Colors.transparent,
                                ),
                                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}