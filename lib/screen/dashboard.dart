import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'setting.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "User";
  String apiTemp = "--";
  String currentCity = "Memuat Lokasi..."; 
  String sportRecommendation = "Menganalisis minatmu...";
  String weatherCondition = "Memuat...";
  List<String> userFavorites = [];

  int currentAQI = 0;
  double currentUV = 0.0;
  String environmentalTips = "Menyiapkan tips untukmu...";

  final String apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0"; 

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _fetchUserProfile();
    await _fetchEnvironmentData();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ Cek mounted sebelum setState agar tidak error saat pindah page
        if (!mounted) return;
        setState(() => userName = user.displayName ?? "User");
        
        final snapshot = await FirebaseDatabase.instance.ref("users/${user.uid}/favorite_sports").get();
        if (snapshot.exists) {
          userFavorites = List<String>.from(snapshot.value as List);
        }
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  // --- LOGIC PENENTUAN STATUS (SESUAI PROMPT) ---
  Map<String, dynamic> _getAQIDetail(int aqi) {
    if (aqi <= 50) return {"status": "Baik", "color": Colors.greenAccent, "tips": "Aman tanpa masker."};
    if (aqi <= 100) return {"status": "Sedang", "color": Colors.yellowAccent, "tips": "Asma harap waspada."};
    return {"status": "Tidak Sehat", "color": Colors.redAccent, "tips": "Gunakan masker!"};
  }

  Map<String, dynamic> _getUVDetail(double uv) {
    if (uv <= 2) return {"status": "Rendah", "color": Colors.greenAccent, "tips": "Aman luar ruangan."};
    if (uv <= 5) return {"status": "Sedang", "color": Colors.yellowAccent, "tips": "Gunakan sunscreen."};
    return {"status": "Tinggi", "color": Colors.orangeAccent, "tips": "Kurangi paparan siang."};
  }

  // --- FETCH DATA (OPENWEATHER DIRECT) ---
  Future<void> _fetchEnvironmentData() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("GPS Error: $e");
    }

    // ✅ Proteksi: Jika user sudah pindah halaman, hentikan proses
    if (!mounted) return; 

    double lat = pos?.latitude ?? -7.9666;
    double lon = pos?.longitude ?? 112.6326;

    final weatherUrl = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id";
    final aqiUrl = "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey";

    try {
      final results = await Future.wait([
        http.get(Uri.parse(weatherUrl)),
        http.get(Uri.parse(aqiUrl)),
      ]);

      // ✅ Proteksi: Cek kembali status mounted sebelum memperbarui UI
      if (!mounted) return; 

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final wData = json.decode(results[0].body);
        final aData = json.decode(results[1].body);

        setState(() {
          apiTemp = wData['main']['temp'].toInt().toString();
          currentCity = wData['name'];
          weatherCondition = wData['weather'][0]['description'];
          
          int rawAQI = aData['list'][0]['main']['aqi'];
          currentAQI = rawAQI * 25;
          double clouds = wData['clouds']['all'].toDouble();
          currentUV = (100 - clouds) / 10;

          environmentalTips = "${_getAQIDetail(currentAQI)['tips']} ${_getUVDetail(currentUV)['tips']}";
          sportRecommendation = _getSmartRecommendation(wData['main']['temp'].toDouble());
        });
      }
    } catch (e) {
      debugPrint("Request Error: $e");
      if (mounted) {
        setState(() => currentCity = "Koneksi Gagal");
      }
    }
  }

  String _getSmartRecommendation(double temp) {
    if (userFavorites.isEmpty) return "Yuk pilih olahraga dulu di Settings!";
    String randomSport = userFavorites[Random().nextInt(userFavorites.length)];
    if (temp > 33) return "Latihan $randomSport Indoor saja Wak! 🏠";
    return "$randomSport ✨\nKondisi luar ruangan mantap!";
  }

  @override
  Widget build(BuildContext context) {
    var aqiInfo = _getAQIDetail(currentAQI);
    var uvInfo = _getUVDetail(currentUV);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 140, 20, 150),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherCard(),
                  const SizedBox(height: 30),
                  const Text("Status Lingkungan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard("Kualitas Udara", aqiInfo['status'], Icons.air, aqiInfo['color']),
                      const SizedBox(width: 15),
                      _buildStatCard("Indeks UV", uvInfo['status'], Icons.sunny, uvInfo['color']),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildTipsCard(environmentalTips),
                ],
              ),
            ),
          ),
          _buildHeader(context),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.location_on, color: Colors.blueAccent, size: 16), const SizedBox(width: 5), Text(currentCity.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 5),
                      Text("$apiTemp° Celsius", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text(weatherCondition.toUpperCase(), style: const TextStyle(color: Color(0xFF008BFF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 50),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            Text(sportRecommendation, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(String tips) {
    return GlassCard(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFF008BFF), child: Icon(Icons.lightbulb_outline, color: Colors.white)),
        title: const Text("Saran Kesehatan", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(tips, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8), 
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(_createRoute()), 
                  child: CircleAvatar(
                    radius: 22, 
                    backgroundColor: const Color(0xFF1C1C1E),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null, 
                    child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white38) : null
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text("LORA SPORTS", style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)), 
                      Text("Halo, $userName", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
                    ]
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(), transitionsBuilder: (context, animation, secondaryAnimation, child) { return SlideTransition(position: animation.drive(Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutQuart))), child: child); });
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))), child: child);
  }
}