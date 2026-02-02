import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WeatherDetailPage extends StatefulWidget {
  final Map<String, dynamic> weatherData; // Data kiriman dari Dashboard
  const WeatherDetailPage({super.key, required this.weatherData});

  @override
  State<WeatherDetailPage> createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  List<String> userSports = [];

  @override
  void initState() {
    super.initState();
    _loadUserSports();
  }

  Future<void> _loadUserSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${user.uid}/favorite_sports")
          .get();
      if (snapshot.exists) {
        setState(() {
          userSports = List<String>.from(snapshot.value as List);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari data cuaca yang dikirim
    String temp = widget.weatherData['temp'] ?? "--";
    String desc = widget.weatherData['desc'] ?? "Tidak diketahui";
    String humidity = widget.weatherData['humidity']?.toString() ?? "0";
    String wind = widget.weatherData['wind']?.toString() ?? "0";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Analisis Cuaca LORA",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // CARD UTAMA CUACA
            _buildMainWeatherCard(temp, desc),
            const SizedBox(height: 25),
            
            // DETAIL STATS (ANGIN & KELEMBAPAN)
            Row(
              children: [
                _buildSmallInfo(
                  "Kelembapan",
                  "$humidity%",
                  Icons.water_drop,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 15),
                _buildSmallInfo(
                  "Kecepatan Angin",
                  "${wind}m/s",
                  Icons.air,
                  Colors.tealAccent,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // REKOMENDASI OLAHRAGA BERDASARKAN PILIHAN USER
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Saran Aktivitas Untukmu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            if (userSports.isEmpty)
              const Text(
                "Belum ada olahraga pilihan, Wak.",
                style: TextStyle(color: Colors.white24),
              )
            else
              ...userSports
                  .map((sport) => _buildSportRecommendationCard(sport, temp))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard(String temp, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF008BFF), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_cloudy_outlined, color: Colors.white, size: 80),
          const SizedBox(height: 15),
          Text(
            "$temp°C",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            desc.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportRecommendationCard(String sport, String tempStr) {
    double temp = double.tryParse(tempStr) ?? 25.0;
    String advice = temp > 30
        ? "Lakukan di tempat teduh, jangan lupa minum!"
        : "Kondisi mantap! Gas terus, Wak.";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF008BFF),
            child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sport,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  advice,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
