import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryBolaDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryBolaDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(data['time'] ?? DateTime.now().toIso8601String());
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Detail Sepak Bola", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['activity'] ?? 'Aktivitas Sepak Bola', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(formattedDate, style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            _buildStat("Kalori Terbakar", "${data['calories'] ?? 0} kcal"),
            _buildStat("Durasi", "${((data['duration_sec'] ?? 0) / 60).round()} menit"),
            // Tambahkan statistik spesifik sepak bola lainnya di sini
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
