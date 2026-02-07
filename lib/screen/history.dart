import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'package:intl/intl.dart';

// ✅ Import sesuai nama file ringkas kamu di folder riwayat
import 'riwayat/lari.dart';
import 'riwayat/sepeda.dart';
import 'riwayat/bmi.dart';
import 'riwayat/home_workout.dart';
import 'riwayat/basket.dart';
import 'riwayat/bola.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),
              
              // --- HEADER TABEL ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildHeaderCell("Aktivitas", flex: 3),
                    _buildHeaderCell("Detail", flex: 6, alignment: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- LIST DATA ---
              Expanded(
                child: user == null
                    ? const Center(child: Text("Silakan Login", style: TextStyle(color: Colors.white)))
                    : StreamBuilder(
                        stream: FirebaseDatabase.instance
                            .ref("users/${user.uid}/history")
                            .orderByChild('time')
                            .onValue,
                        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF008BFF)));
                          }

                          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                            return const Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.white54)));
                          }

                          Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                          List<Map<dynamic, dynamic>> historyList = [];
                          
                          values.forEach((key, value) {
                            var item = Map<dynamic, dynamic>.from(value);
                            item['key'] = key;
                            historyList.add(item);
                          });

                          historyList.sort((a, b) => (b['time'] ?? "").compareTo(a['time'] ?? ""));

                          return ListView.builder(
                            itemCount: historyList.length,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final data = historyList[index];
                              final String activity = (data['activity'] ?? 'Aktivitas').toString().toUpperCase();
                              final String timeStr = data['time'] ?? '';
                              final String type = (data['type'] ?? '').toString().toUpperCase();

                              String formattedDate = "N/A";
                              if (timeStr.isNotEmpty) {
                                DateTime dt = DateTime.parse(timeStr);
                                formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                              }

                              IconData activityIcon = Icons.fitness_center;
                              if (type == 'TRACKING') {
                                activityIcon = activity.contains('SEPEDA') ? Icons.directions_bike : Icons.directions_run;
                              } else if (type == 'BMI' || activity.contains('BMI')) {
                                activityIcon = Icons.monitor_weight_rounded;
                              }

                              return Dismissible(
                                key: Key(data['key']),
                                direction: DismissDirection.endToStart,
                                background: _buildDeleteBackground(),
                                confirmDismiss: (direction) async {
                                  await FirebaseDatabase.instance
                                      .ref("users/${user.uid}/history/${data['key']}")
                                      .remove();
                                  return true;
                                },
                                // ✅ PERBAIKAN NAVIGASI DINAMIS
                                child: InkWell(
                                  onTap: () {
                                    if (type == 'BMI' || activity.contains('BMI')) {
                                      // Membuka file bmi.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryBMIDetailPage(data: data)));
                                    } else if (activity.contains('LARI')) {
                                      // Membuka file lari.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryLariDetailPage(data: data)));
                                    } else if (activity.contains('SEPEDA')) {
                                      // Membuka file sepeda.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistorySepedaDetailPage(data: data)));
                                    } else if (activity.contains('HOME WORKOUT')) {
                                      // Membuka file home_workout.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryWorkoutDetailPage(data: data)));
                                    } else if (activity.contains('BASKET')) {
                                      // Membuka file basket.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryBasketDetailPage(data: data)));
                                    } else if (activity.contains('BOLA')) {
                                      // Membuka file bola.dart
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryBolaDetailPage(data: data)));
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C1E),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Icon(activityIcon, color: const Color(0xFF008BFF), size: 24),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data['activity'] ?? 'Aktivitas', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                                    Text(formattedDate, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: (type == 'BMI' || activity.contains('BMI'))
                                            ? _buildBMIStats(data)
                                            : _buildTrackingStats(data),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          _buildFixedHeader(),
        ],
      ),
    );
  }

  // --- WIDGET STATISTIK & HEADER ---
  Widget _buildTrackingStats(Map data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildStatItem(data['distance_km']?.toString() ?? "0", "km"),
        const SizedBox(width: 12),
        _buildStatItem(data['calories']?.toString() ?? "0", "kcal"),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBMIStats(Map data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            data['status'] ?? "N/A",
            style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildStatItem(String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, TextAlign alignment = TextAlign.start}) {
    return Expanded(flex: flex, child: Text(title, textAlign: alignment, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)));
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.delete_forever, color: Colors.white),
    );
  }

  Widget _buildFixedHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
        child: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFF008BFF), size: 28),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("LORA SYSTEM", style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 2)),
                Text("Activity History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}