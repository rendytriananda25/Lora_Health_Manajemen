import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/settings/presentation/providers/settings_provider.dart';
import 'personal_info_page.dart';
import 'security_page.dart';
import 'notification_page.dart';
import 'language_page.dart';
import '../widgets/setting_widgets.dart';
import 'package:lora_1/auth/login_page.dart';
import 'package:lora_1/features/dashboard/data/nutrition_data.dart';
import 'package:lora_1/features/map/data/workout_data.dart';
import 'package:lora_1/features/gamification/badges_page.dart';
import 'package:lora_1/features/gamification/badge_translator.dart';
import 'package:lora_1/features/dashboard/presentation/providers/dashboard_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).fetchProfileData();
    });
  }

  Future<void> _handleLogout() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.boxColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          lang.translate('settings.logoutAccount'),
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          lang.translate('settings.confirmLogoutBody'),
          style: TextStyle(color: theme.subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              lang.translate('errors.cancel'),
              style: TextStyle(color: theme.subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.logoutBtnBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              lang.translate('settings.logout'),
              style: TextStyle(
                color: theme.logoutBtnText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).clearUserData();
      }

      await Provider.of<SettingsProvider>(context, listen: false).logout();
      
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // 🔥 FUNGSI RAHASIA ADMIN
  Future<void> _adminUpdateData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF008BFF)),
      ),
    );

    await NutritionData.seedToFirebase();
    await WorkoutData.seedToFirebase();

    if (mounted) {
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Database Nutrisi & Workout Berhasil Diupdate!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GLOBAL THEME
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.bgColor,
      body: SafeArea(
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            return Column(
              children: [
                // ==========================================
                // 1. BAGIAN ATAS FIXED (Header + Tombol Tema)
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.translate('settings.title'),
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 🔥 TOMBOL THEME (Global)
                      GestureDetector(
                        onTap: () {
                          themeProvider.toggleTheme();
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              RotationTransition(
                                turns: child.key == const ValueKey('icon1')
                                    ? Tween<double>(
                                        begin: 1,
                                        end: 0.75,
                                      ).animate(anim)
                                    : Tween<double>(
                                        begin: 0.75,
                                        end: 1,
                                      ).animate(anim),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            key: ValueKey(isDarkMode ? 'icon1' : 'icon2'),
                            color: isDarkMode ? Colors.white : Colors.amber,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 2. PROFIL FIXED
                // ==========================================
                Consumer<SettingsProvider>(
                  builder: (context, provider, _) {
                    final profile = provider.profile;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SettingProfileCard(
                        fullName: profile?.fullName ?? "Loading...",
                        email: profile?.email ?? "Loading...",
                        photoUrl: profile?.photoUrl,
                        localPhotoPath: profile?.localPhotoPath,
                        onPhotoTap: () async {
                          await provider.pickAndSaveImage();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageProvider.translate('settings.photoUpdated')),
                                backgroundColor: const Color(0xFF008BFF),
                              ),
                            );
                          }
                        },
                        isDarkMode: isDarkMode,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 3. MENU BOX TENGAH YANG BISA DI-SCROLL
                // ==========================================
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.boxColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: themeProvider.borderColor),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    // 🔥 BAGIAN INI SAJA YANG BISA DI SCROLL
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.translate(
                              'settings.accountSettings',
                            ),
                            style: TextStyle(
                              color: themeProvider.subTextColor,
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
                            isDarkMode: isDarkMode, // ✅ Pass Global Theme
                            onTap: () async {
                              await _pushPopup(const PersonalInfoPage());
                              if (mounted) {
                                Provider.of<SettingsProvider>(context, listen: false).fetchProfileData();
                              }
                            },
                          ),
                          SettingItem(
                            icon: Icons.emoji_events_outlined,
                            title: BadgeTranslator.translateTitle("Pencapaian & Badges", languageProvider),
                            isDarkMode: isDarkMode,
                            onTap: () => _pushPopup(const BadgesPage()),
                          ),
                          SettingItem(
                            icon: Icons.lock_outline,
                            title: languageProvider.translate(
                              'settings.security',
                            ),
                            isDarkMode: isDarkMode, // ✅ Pass Global Theme
                            onTap: () => _pushPopup(const SecurityPage()),
                          ),
                          SettingItem(
                            icon: Icons.notifications_none,
                            title: languageProvider.translate(
                              'settings.notifications',
                            ),
                            isDarkMode: isDarkMode,
                            onTap: () => _pushPopup(const NotificationPage()),
                          ),
                          SettingItem(
                            icon: Icons.language,
                            title: languageProvider.translate(
                              'settings.language',
                            ),
                            isDarkMode: isDarkMode,
                            onTap: () => _pushPopup(const LanguagePage()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // 4. BAGIAN BAWAH FIXED (Logout & Versi)
                // ==========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    children: [
                      _buildLogoutButton(themeProvider), // ✅ Pass Theme
                      const SizedBox(height: 15),
                      // TOMBOL RAHASIA ADMIN
                      GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1C1C1E),
                              title: const Text(
                                "Admin Mode",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Update data lora sekarang?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _adminUpdateData();
                                  },
                                  child: const Text(
                                    "UPDATE",
                                    style: TextStyle(
                                      color: Color(0xFF008BFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Lora Version 1.0.0',
                          style: TextStyle(
                            color: themeProvider.subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.logoutBtnBg, // ✅ Custom Logout Color
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: theme.isDarkMode
                ? const BorderSide(color: Colors.redAccent, width: 0.2)
                : BorderSide.none,
          ),
        ),
        child: Text(
          Provider.of<LanguageProvider>(
            context,
          ).translate('settings.logoutAccount'),
          style: TextStyle(
            color: theme.logoutBtnText, // ✅ Custom Text Color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔥 CUSTOM POP-UP TRANSITION
  Future<void> _pushPopup(Widget page) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // Efek membal "pop"
            reverseCurve: Curves.easeIn,
          );

          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(curvedAnimation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }
}

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
