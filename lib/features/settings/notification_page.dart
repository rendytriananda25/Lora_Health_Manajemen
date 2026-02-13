import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'widgets/setting_widgets.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(title: lang.translate('notification.title')),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildSwitchTile(
                    lang.translate('notification.pushNotifications'),
                    lang.translate('notification.pushDescription'),
                    pushNotify,
                    (val) => setState(() => pushNotify = val),
                  ),
                  _buildSwitchTile(
                    lang.translate('notification.activityUpdates'),
                    lang.translate('notification.activityDescription'),
                    activityNotify,
                    (val) => setState(() => activityNotify = val),
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
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF008BFF),
      ),
    );
  }
}
