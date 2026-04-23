import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/services/language_provider.dart';
import 'core/services/theme_provider.dart';
import 'features/notification/notification_service.dart';
import 'features/notification/workout_reminder_service.dart';
import 'screen/navbar.dart';
import 'screen/onboarding_screen.dart';
import 'setup/setup_page.dart';
import 'features/dashboard/data/nutrition_data.dart';
import 'features/map/data/workout_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  debugPrint("🚀 Main: Theme Initialized");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await WorkoutReminderService.instance.initDefault();
  NutritionData.fetchFromFirebase();
  WorkoutData.fetchFromFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: themeProvider),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lora Assistant',
      theme: themeProvider.themeData,
      home: Builder(
        builder: (context) {
          final isDark = themeProvider.isDarkMode;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: themeProvider.bgColor,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: themeProvider.bgColor, // Use Theme Color
                  body: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                  ),
                );
              }
              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;
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
                    if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                      return const Navbar();
                    }
                    return const SetupPage();
                  },
                );
              }
              return const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}
