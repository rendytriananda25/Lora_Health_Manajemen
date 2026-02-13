import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ✅ Tambahkan Provider
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
import 'core/services/language_provider.dart'; // ✅ Pastikan path ini benar
import 'screen/navbar.dart'; 
import 'screen/onboarding_screen.dart'; 
import 'screen/sports_selection.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🌍 1. Inisialisasi Language Provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

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

  runApp(
    MultiProvider(
      providers: [
        // ✅ Daftarkan Language Provider agar bisa diakses seluruh aplikasi
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
        ),
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
    // ✅ Gunakan Consumer agar saat bahasa berubah di Setting, seluruh App otomatis berubah
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lora Assistant',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF008BFF), 
              brightness: Brightness.dark
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.black, // Konsisten dengan tema gelap
          ),
          
          // --- LOGIC ROUTING PINTAR (RENDY TRIANANDA) ---
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // A. Loading State
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0F172A),
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF008BFF))),
                );
              }

              // B. Jika User SUDAH LOGIN
              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;

                // Cek ke Realtime Database untuk Favorite Sports
                return FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instanceFor(
                          app: FirebaseAuth.instance.app,
                          databaseURL: dbUrl,
                        )
                      .ref("users/${user.uid}/favorite_sports")
                      .get()
                      .timeout(const Duration(seconds: 10)), 
                  builder: (context, dbSnapshot) {
                    if (dbSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: Color(0xFF0F172A),
                        body: Center(child: CircularProgressIndicator(color: Color(0xFF008BFF))),
                      );
                    }

                    // Jika data olahraga ADA -> Ke Dashboard/Navbar
                    if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                      return const Navbar();
                    }

                    // Jika data olahraga TIDAK ADA -> Pilih Olahraga (Onboarding step 2)
                    return const SportsSelectionPage(); 
                  },
                );
              }

              // C. Jika User BELUM LOGIN -> Onboarding
              return const OnboardingScreen();
            },
          ),
        );
      }
    );
  }
}