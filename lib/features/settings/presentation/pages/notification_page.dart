import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart'; // ✅ Added
import '../widgets/setting_widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool pushNotify = true;
  bool activityNotify = false;

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
              title: lang.translate('notification.title'),
              isDarkMode: theme.isDarkMode, // ✅ Pass Theme
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildSwitchTile(
                    lang.translate('notification.pushNotifications'),
                    lang.translate('notification.pushDescription'),
                    pushNotify,
                    (val) => setState(() => pushNotify = val),
                    theme, // ✅ Pass Theme
                  ),
                  const SizedBox(height: 20),
                  _buildSwitchTile(
                    lang.translate('notification.activityUpdates'),
                    lang.translate('notification.activityDescription'),
                    activityNotify,
                    (val) => setState(() => activityNotify = val),
                    theme, // ✅ Pass Theme
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String sub,
    bool value,
    Function(bool) onChanged,
    ThemeProvider theme,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          sub,
          style: TextStyle(color: theme.subTextColor, fontSize: 12),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF008BFF),
        inactiveTrackColor: theme.isDarkMode ? Colors.white10 : Colors.black12,
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
    );
  }
}
