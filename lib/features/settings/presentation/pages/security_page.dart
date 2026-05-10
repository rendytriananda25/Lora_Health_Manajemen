import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart'; // ✅ Added
import '../widgets/setting_widgets.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context); // ✅ Theme

    return Scaffold(
      backgroundColor: theme.bgColor, // ✅ Adaptive
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(
              title: lang.translate('security.title'),
              isDarkMode: theme.isDarkMode, // ✅ Pass Theme
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 20),
                  _buildSecurityTile(
                    Icons.lock_reset,
                    lang.translate('security.changePassword'),
                    theme.isDarkMode,
                  ),
                  _buildSecurityTile(
                    Icons.fingerprint,
                    lang.translate('security.biometric'),
                    theme.isDarkMode,
                  ),
                  _buildSecurityTile(
                    Icons.devices,
                    lang.translate('security.connectedDevices'),
                    theme.isDarkMode,
                  ),
                  _buildSecurityTile(
                    Icons.privacy_tip_outlined,
                    lang.translate('security.privacyPolicy'),
                    theme.isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile(IconData icon, String title, bool isDarkMode) {
    return SettingItem(
      icon: icon,
      title: title,
      onTap: () {},
      isDarkMode: isDarkMode, // ✅ Pass Theme
    );
  }
}
