import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryWorkoutDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryWorkoutDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    // 1. Parsing Waktu & Tanggal (Safe Mode)
    DateTime dt;
    try {
      dt = DateTime.parse(data['time']);
    } catch (e) {
      dt = DateTime.now();
    }
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    // 2. Parsing Durasi & Kalori (Pakai num biar aman int/double)
    int durationSec = (data['duration_sec'] as num? ?? 0).toInt();
    int durationMin = (durationSec / 60).ceil();
    int calories = (data['calories'] as num? ?? 0).toInt();

    // 3. Parsing Details
    List<String> exerciseList = [];

    // ✅ SUPPORT FORMAT BARU (List of Maps)
    if (data['workout_details'] != null && data['workout_details'] is List) {
      final list = data['workout_details'] as List;
      for (var item in list) {
        // Handle Map
        if (item is Map) {
          final name = item['name'] ?? 'Unknown';
          final result = item['result'] ?? '-';
          exerciseList.add("$name: $result");
        }
        // Handle "Object" from Firebase converted to Map equivalent
        else if (item != null) {
          try {
            // Sometimes Firebase returns List<Object?> which are effectively Maps
            final map = Map<String, dynamic>.from(item as dynamic);
            final name = map['name'] ?? 'Unknown';
            final result = map['result'] ?? '-';
            exerciseList.add("$name: $result");
          } catch (e) {
            exerciseList.add(item.toString());
          }
        }
      }
    }
    // ✅ SUPPORT FORMAT LAMA (String)
    else if (data['details'] != null) {
      String detailsRaw = data['details'].toString();
      if (detailsRaw.isNotEmpty &&
          detailsRaw != "Tidak ada gerakan diselesaikan") {
        exerciseList = detailsRaw.split(", ");
      }
    }

    // 4. Hitung Total Sets
    int totalSets = exerciseList.isEmpty ? 0 : exerciseList.length;

    // 5. Logic Intensitas
    double calPerMin = durationMin > 0 ? (calories / durationMin) : 0;
    String intensity = "RINGAN";
    double intensityValue = 0.3;

    if (calPerMin > 8) {
      intensity = "TINGGI 🔥";
      intensityValue = 0.9;
    } else if (calPerMin > 4) {
      intensity = "SEDANG ⚡";
      intensityValue = 0.6;
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          formattedDate,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Row Atas: Total Sets & Kalori/Waktu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Biar sejajar atas
              children: [
                // KOLOM KIRI: TOTAL SETS
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200, // Fixed height biar aman
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7B8F5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    // Gunakan SpaceBetween, JANGAN Spacer() di dalam ScrollView
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.black54),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TOTAL GERAKAN",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "$totalSets",
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: totalSets > 0 ? 1.0 : 0.0,
                              backgroundColor: Colors.black12,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // KOLOM KANAN: KALORI & WAKTU
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallCard(
                        color: const Color(0xFFB2EBF2),
                        title: "KALORI",
                        value: "$calories",
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
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF90CAF9),
                borderRadius: BorderRadius.circular(30),
              ),
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
                          Text(
                            "INTENSITAS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        intensity,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(), // Spacer di sini AMAN karena di dalam Row Horizontal
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: intensityValue,
                      strokeWidth: 8,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Card Detail Gerakan (List Real)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.boxColor, // Adaptive Color
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.textColor.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DETAIL GERAKAN",
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (exerciseList.isEmpty)
                    Text(
                      "Tidak ada data gerakan.",
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.54),
                      ),
                    )
                  else
                    ...exerciseList.map((item) {
                      List<String> parts = item.split(": ");
                      String name = parts[0];
                      String val = parts.length > 1 ? parts[1] : "-";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildMovementRow(name, val, 0.8, theme),
                      );
                    }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildSmallCard({
    required Color color,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 92.5, // (200 - 15) / 2 -> Biar pas sejajar sama card kiri
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementRow(
    String label,
    String value,
    double progress,
    ThemeProvider theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFC7B8F5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.textColor.withOpacity(0.1),
            color: const Color(0xFF90CAF9),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
