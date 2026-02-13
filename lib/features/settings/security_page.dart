import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'widgets/setting_widgets.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(title: lang.translate('security.title')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 20),
                  _buildSecurityTile(
                    Icons.lock_reset,
                    lang.translate('security.changePassword'),
                    lang.translate('security.changePasswordDesc'),
                  ),
                  _buildSecurityTile(
                    Icons.fingerprint,
                    lang.translate('security.biometric'),
                    lang.translate('security.biometricDesc'),
                  ),
                  _buildSecurityTile(
                    Icons.devices,
                    lang.translate('security.connectedDevices'),
                    lang.translate('security.connectedDevicesDesc'),
                  ),
                  _buildSecurityTile(
                    Icons.privacy_tip_outlined,
                    lang.translate('security.privacyPolicy'),
                    lang.translate('security.privacyPolicyDesc'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile(IconData icon, String title, String subtitle) {
    return SettingItem(icon: icon, title: title, onTap: () {});
  }
}
