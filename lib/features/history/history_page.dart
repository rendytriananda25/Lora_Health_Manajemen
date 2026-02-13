import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/history_service.dart';
import 'widgets/history_card.dart';
// Import halaman detail
import 'package:lora_1/screen/riwayat/lari.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/screen/riwayat/sepeda.dart';
import 'package:lora_1/screen/riwayat/bmi.dart';
import 'package:lora_1/screen/riwayat/home_workout.dart';
import 'package:lora_1/screen/riwayat/basket.dart';
import 'package:lora_1/screen/riwayat/bola.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryService historyService = HistoryService();
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 120),
              Expanded(
                child: StreamBuilder(
                  stream: historyService.getHistoryStream(),
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF008BFF)));
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return Center(child: Text(lang.translate('history.empty'), style: const TextStyle(color: Colors.white54)));
                    }

                    // Olah Data
                    Map values = snapshot.data!.snapshot.value as Map;
                    List<Map> historyList = [];
                    values.forEach((key, value) {
                      var item = Map.from(value);
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
                        return Dismissible(
                          key: Key(data['key']),
                          direction: DismissDirection.endToStart,
                          background: _buildDeleteBackground(),
                          onDismissed: (_) => historyService.deleteHistory(data['key']),
                          child: HistoryCard(
                            data: data,
                            onTap: () => _navigateToDetail(context, data),
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
          _buildFixedHeader(lang),
        ],
      ),
    );
  }

  // Fungsi Navigasi
  void _navigateToDetail(BuildContext context, Map data) {
    final String activity = (data['activity'] ?? '').toString().toUpperCase();
    final String type = (data['type'] ?? '').toString().toUpperCase();

    Widget page;
    if (type == 'BMI' || activity.contains('BMI')) {
      page = HistoryBMIDetailPage(data: data);
    } else if (activity.contains('LARI')) {
      page = HistoryLariDetailPage(data: data);
    } else if (activity.contains('SEPEDA')) {
      page = HistorySepedaDetailPage(data: data);
    } else if (activity.contains('HOME WORKOUT')) {
      page = HistoryWorkoutDetailPage(data: data);
    } else if (activity.contains('BASKET')) {
      page = HistoryBasketDetailPage(data: data);
    } else if (activity.contains('BOLA')) {
      page = HistoryBolaDetailPage(data: data);
    } else { return; }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // Widget Header & Delete Background tetap di sini karena sederhana
  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.delete_forever, color: Colors.white),
    );
  }

  Widget _buildFixedHeader(LanguageProvider lang) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xFF008BFF), size: 28),
            const SizedBox(width: 15),
            Text(lang.translate('history.title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}