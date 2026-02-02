import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryBMIDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryBMIDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Format tanggal lokalisasi Indonesia
    DateTime dt = DateTime.parse(data['time'] ?? DateTime.now().toIso8601String());
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. VISUALISASI KARAKTER & ANGKA TINGGI/BERAT
              Expanded(
                flex: 4,
                child: _buildBMIVisualization(),
              ),
              
              // 2. PANEL STATISTIK BAWAH (Tanpa Tombol)
              Expanded(
                flex: 2, // Flex dikurangi agar panel tidak terlalu tinggi
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("HASIL KALKULASI BMI", 
                        style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(formattedDate, 
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white10, height: 40),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("BMI SKOR", data['activity']?.replaceAll("Cek BMI: ", "") ?? "0", "INDEX"),
                          _buildStatItem("STATUS", data['status'] ?? "NORMAL", "LEVEL"),
                        ],
                      ),
                      // Tombol Kembali dibuang agar lebih minimalis sesuai permintaan Rendy
                    ],
                  ),
                ),
              )
            ],
          ),
          
          // Tombol Kembali (Navigasi Utama)
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.arrow_back, color: Colors.white)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIVisualization() {
    String status = (data['status'] ?? "NORMAL").toString().toUpperCase();
    String weightVal = data['weight']?.toString() ?? "--";
    String heightVal = data['height']?.toString() ?? "--";
    
    Color bodyColor;
    if (status.contains("KURANG")) {
      bodyColor = Colors.lightBlueAccent;
    } else if (status.contains("NORMAL")) {
      bodyColor = const Color(0xFF5EEAD4); 
    } else if (status.contains("OVERWEIGHT")) {
      bodyColor = Colors.orangeAccent;
    } else {
      bodyColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF1C1C1E),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 50, bottom: 60, top: 100,
            child: _buildRulerColumn("Weight", weightVal, "kg", Icons.monitor_weight_outlined),
          ),
          Positioned(
            right: 50, bottom: 60, top: 100,
            child: _buildRulerColumn("Height", heightVal, "cm", Icons.height_rounded),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/bmi_character.png', 
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, color: Colors.white24, size: 200);
                },
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: bodyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bodyColor.withOpacity(0.2)),
                ),
                child: Text(status, 
                  style: TextStyle(color: bodyColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulerColumn(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 22),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 15),
        Expanded(
          child: Container(
            width: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(12, (index) => Container(
                width: index % 4 == 0 ? 10 : 5, 
                height: 1.5, 
                color: Colors.white12
              )),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}