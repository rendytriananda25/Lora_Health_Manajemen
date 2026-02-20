import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ✅ Tambahkan Provider
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
import 'core/services/language_provider.dart'; // ✅ Pastikan path ini benar
import 'core/services/theme_provider.dart'; // ✅ Added ThemeProvider
import 'features/notification/notification_service.dart';
import 'features/notification/workout_reminder_service.dart';
import 'screen/navbar.dart';
import 'screen/onboarding_screen.dart';
import 'setup/setup_page.dart';
import 'features/dashboard/data/nutrition_data.dart';
import 'features/map/data/workout_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 1. Inisialisasi Language & Theme Provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  final themeProvider = ThemeProvider(); // ✅ Init Theme
  await themeProvider.initialize();
  debugPrint("🚀 Main: Theme Initialized");

  // 📱 2. Atur UI Overlay (Status Bar & Orientasi)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 🔥 3. Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifikasi + reminder
  await NotificationService.instance.init();
  await WorkoutReminderService.instance.initDefault();

  // 🚀 4. Load Data Global (Background)
  NutritionData.fetchFromFirebase();
  WorkoutData.fetchFromFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: themeProvider), // ✅ Inject Theme
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final String dbUrl =
      "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app";

  @override
  Widget build(BuildContext context) {
    // ✅ Watch Providers for Global Updates
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Note: Language is used inside consumers/widgets usually,
    // but we can listen here if needed for Title updates.

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lora Assistant',
      theme: themeProvider.themeData, // ✅ Apply Dynamic Theme
      // --- LOGIC ROUTING PINTAR (RENDY TRIANANDA) ---
      home: Builder(
        builder: (context) {
          // 📱 Dynamic System UI Overlay
          // Memastikan Navbar & Status Bar ikut berubah warna sesuai tema
          final isDark = themeProvider.isDarkMode;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor:
                  themeProvider.bgColor, // Ikuti warna background
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // A. Loading State
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: themeProvider.bgColor, // Use Theme Color
                  body: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                  ),
                );
              }

              // B. Jika User SUDAH LOGIN
              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;

                // Cek ke Realtime Database untuk Favorite Sports
                return FutureBuilder<DataSnapshot>(
                  future:
                      FirebaseDatabase.instanceFor(
                            app: FirebaseAuth.instance.app,
                            databaseURL: dbUrl,
                          )
                          .ref("users/${user.uid}/favorite_sports")
                          .get()
                          .timeout(const Duration(seconds: 10)),
                  builder: (context, dbSnapshot) {
                    if (dbSnapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        backgroundColor: themeProvider.bgColor,
                        body: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF008BFF),
                          ),
                        ),
                      );
                    }

                    // Jika data olahraga ADA -> Ke Dashboard/Navbar
                    if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                      return const Navbar();
                    }

                    // Jika data olahraga TIDAK ADA -> Pilih Olahraga (Onboarding step 2)
                    return const SetupPage();
                  },
                );
              }

              // C. Jika User BELUM LOGIN -> Onboarding
              return const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}
