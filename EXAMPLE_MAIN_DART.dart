// 📝 Example: Update main.dart like this

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/screen/login.dart';
import 'package:lora_1/screen/onboarding_screen.dart';
import 'package:lora_1/screen/navbar.dart';
import 'package:lora_1/screen/sports_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Initialize Firebase
  // await Firebase.initializeApp();

  // 🌍 Initialize Language Provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // 📱 System UI Overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // ✅ Language Provider - Makes translations available everywhere
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
        ),
        // Add other providers here as needed
        // ChangeNotifierProvider(create: (_) => YourOtherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lora',
      theme: _buildTheme(),
      home: const _AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF008BFF),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// App Entry Point with Auth Logic
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Loading state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated - show login
        if (authSnapshot.data == null) {
          return const LoginScreen();
        }

        // Authenticated - check if user completed onboarding
        User user = authSnapshot.data!;
        return FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance
              .ref("users/${user.uid}/favorite_sports")
              .get(),
          builder: (context, sportSnapshot) {
            if (sportSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Has favorite sports - go to navbar/dashboard
            if (sportSnapshot.data?.exists ?? false) {
              return const Navbar();
            }

            // No favorite sports - show sport selection
            return const SportsSelectionPage();
          },
        );
      },
    );
  }
}
