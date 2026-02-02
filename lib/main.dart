import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ WAJIB: Kamus untuk SystemUIOverlayStyle
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
import 'screen/navbar.dart'; 
import 'screen/onboarding_screen.dart'; 
import 'screen/login.dart';            
import 'screen/sports_selection.dart';   

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ PERBAIKAN: Menghilangkan error 'Couldn't find constructor'
    SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      // Hapus systemNavigationBarColor jika error
      // systemNavigationBarColor: Colors.black,
      // systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Mengunci orientasi ke Portrait agar UI Tugas Akhirmu tetap rapi
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget { // ✅ Sudah bersih dari logika Alarm
  const MyApp({super.key});

  final String dbUrl =
      "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lora Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008BFF), 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
      ),
      
      // --- LOGIC ROUTING PINTAR (RENDY TRIANANDA) ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. Loading State
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF008BFF))),
            );
          }

          // 2. Jika User SUDAH LOGIN
          if (authSnapshot.hasData && authSnapshot.data != null) {
            final user = authSnapshot.data!;

            // Cek ke Realtime Database
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

                // Jika data olahraga ADA -> Ke Dashboard
                if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                  return const Navbar();
                }

                // Jika data olahraga TIDAK ADA -> Pilih Olahraga
                return const SportsSelectionPage(); 
              },
            );
          }

          // 3. Jika User BELUM LOGIN -> Onboarding
          return const OnboardingScreen();
        },
      ),
    );
  }
}