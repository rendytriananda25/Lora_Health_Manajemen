import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

import 'personal_info_page.dart';
import 'security_page.dart';
import 'notification_page.dart';
import 'language_page.dart';
import 'widgets/setting_widgets.dart';
import '../../screen/login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String fullName = "Loading...";
  String email = "Loading...";
  String? photoUrl;

  final user = FirebaseAuth.instance.currentUser;
  final String dbUrl =
      "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app";

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (user != null) {
      setState(() {
        email = user!.email ?? "No Email";
        fullName = user!.displayName ?? "User";
        photoUrl = user!.photoURL;
      });

      try {
        FirebaseDatabase db = FirebaseDatabase.instanceFor(
          app: FirebaseAuth.instance.app,
          databaseURL: dbUrl,
        );
        final snapshot = await db.ref("users/${user!.uid}").get();
        if (snapshot.exists && mounted) {
          final data = snapshot.value as Map?;
          final dbName =
              data?['username']?.toString() ??
              data?['full_name']?.toString();
          if (dbName != null && dbName.isNotEmpty) {
            setState(() => fullName = dbName);
          }
        }
      } catch (e) {
        debugPrint("Error Load DB: $e");
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            return Column(
              children: [
                SettingHeader(
                  title: languageProvider.translate('settings.title'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingProfileCard(
                          fullName: fullName,
                          email: email,
                          photoUrl: photoUrl,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          languageProvider.translate(
                            'settings.accountSettings',
                          ),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        SettingItem(
                          icon: Icons.person_outline,
                          title: languageProvider.translate(
                            'settings.personalInfo',
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalInfoPage(),
                              ),
                            );
                            if (mounted) _fetchProfileData();
                          },
                        ),
                        SettingItem(
                          icon: Icons.lock_outline,
                          title: languageProvider.translate(
                            'settings.security',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SecurityPage(),
                            ),
                          ),
                        ),
                        SettingItem(
                          icon: Icons.notifications_none,
                          title: languageProvider.translate(
                            'settings.notifications',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          ),
                        ),
                        SettingItem(
                          icon: Icons.language,
                          title: languageProvider.translate(
                            'settings.language',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguagePage(),
                            ),
                          ),
                        ),

                        const Spacer(),
                        _buildLogoutButton(),
                        const SizedBox(height: 65),
                        Center(
                          child: Text(
                            'Lora Version 1.0.0',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(
            255,
            255,
            0,
            0,
          ).withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 0.2),
          ),
        ),
        child: Text(
          Provider.of<LanguageProvider>(
            context,
          ).translate('settings.logoutAccount'),
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ✅ PLACEHOLDER HALAMAN AGAR TIDAK ERROR SAAT DIKLIK
class SubSettingPlaceholder extends StatelessWidget {
  final String title;
  const SubSettingPlaceholder({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Text(
          "Halaman $title menyusul Wak!",
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
