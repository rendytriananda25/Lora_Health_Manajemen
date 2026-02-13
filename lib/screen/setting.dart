import 'dart:ui';
import 'package:flutter/material.dart';

// ✅ FILE INI STANDALONE - TANPA KONEKSI KE PAGE MANAPUN
// Hanya untuk referensi atau testing isolasi

class SettingsPage extends StatefulWidget { 
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("SETTINGS PAGE - STANDALONE FILE", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.orange, size: 60),
            const SizedBox(height: 20),
            const Text(
              "FILE STANDALONE",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ini file tidak terhubung ke page manapun\nGunakan untuk referensi atau testing isolasi",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Content Include:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildContentItem("✅ Profile Information"),
                  _buildContentItem("✅ Settings Menu Items"),
                  _buildContentItem("✅ Logout Functionality"),
                  _buildContentItem("✅ Firebase Integration"),
                  _buildContentItem("✅ Sub-pages (Personal, Security, Notifications, Language)"),
                  _buildContentItem("✅ User Profile Card Component"),
                  _buildContentItem("✅ Settings Item Widget"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}

// ==========================================
// 📄 HALAMAN-HALAMAN BARU (PLACEHOLDER)
// ==========================================

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const SubSettingPage(title: "Personal Information");
  }
}

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const SubSettingPage(title: "Security & Privacy");
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const SubSettingPage(title: "Notification Settings");
  }
}

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const SubSettingPage(title: "Language (Bahasa)");
  }
}

// Template Halaman Sub-Setting biar rapi
class SubSettingPage extends StatelessWidget {
  final String title;
  const SubSettingPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              color: Colors.white.withOpacity(0.2),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "Coming Soon",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
