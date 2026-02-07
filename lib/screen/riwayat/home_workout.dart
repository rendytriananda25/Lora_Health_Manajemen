import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryWorkoutDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryWorkoutDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Parsing data dasar
    DateTime dt = DateTime.parse(data['time'] ?? DateTime.now().toIso8601String());
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);
    
    // Variabel spesifik workout (sesuaikan dengan isi Firebase kamu)
    int durationMin = ((data['duration_sec'] ?? 0) / 60).round();
    int sets = data['total_sets'] ?? 4;
    String intensity = data['intensity'] ?? "8/10";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Home Workout", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Row Atas: Total Sets & Kalori
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildGridCard(
                    color: const Color(0xFFC7B8F5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.black54),
                        const Spacer(),
                        const Text("TOTAL SETS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                        Text("$sets", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: 0.7, backgroundColor: Colors.black12, color: Colors.black.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallCard(
                        color: const Color(0xFFB2EBF2),
                        title: "KALORI",
                        value: "${data['calories'] ?? 0}",
                        unit: "KCAL",
                        icon: Icons.local_fire_department,
                      ),
                      const SizedBox(height: 15),
                      _buildSmallCard(
                        color: const Color(0xFFA5D6A7),
                        title: "WAKTU",
                        value: "$durationMin",
                        unit: "MENIT",
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Card Intensitas
            _buildGridCard(
              height: 140,
              width: double.infinity,
              color: const Color(0xFF90CAF9),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.black54, size: 20),
                          SizedBox(width: 5),
                          Text("INTENSITAS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(intensity, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: 8,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black45),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Card Gerakan Terbaik
            _buildGridCard(
              width: double.infinity,
              color: const Color(0xFF312E49),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GERAKAN TERBAIK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildMovementRow("Push-up", "60 REPS", 0.8),
                  const SizedBox(height: 20),
                  _buildMovementRow("Plank", "4 MENIT", 0.6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({required Widget child, Color? color, double? height, double? width}) {
    return Container(
      width: width,
      height: height ?? 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: child,
    );
  }

  Widget _buildSmallCard({required Color color, required String title, required String value, required String unit, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 5),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildMovementRow(String label, String value, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: const Color(0xFF90CAF9),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}