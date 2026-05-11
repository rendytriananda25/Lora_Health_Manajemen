import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/history/presentation/providers/history_provider.dart';
import 'package:lora_1/features/history/widgets/history_card.dart';

import 'package:lora_1/screen/riwayat/lari.dart';
import 'package:lora_1/screen/riwayat/sepeda.dart';
import 'package:lora_1/screen/riwayat/bmi.dart';
import 'package:lora_1/screen/riwayat/home_workout.dart';
import 'package:lora_1/screen/riwayat/basket.dart';
import 'package:lora_1/screen/riwayat/bola.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 120),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: historyProvider.historyStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF008BFF),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          lang.translate('history.empty'),
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.54),
                          ),
                        ),
                      );
                    }

                    final historyList = snapshot.data!;

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
                          onDismissed: (_) => historyProvider.deleteHistory(data['key']),
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
          _buildFixedHeader(lang, theme),
        ],
      ),
    );
  }

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
    } else if (activity.contains('HOME WORKOUT') || activity.contains('HOME_WORKOUT')) {
      page = HistoryWorkoutDetailPage(data: data);
    } else if (activity.contains('BASKET')) {
      page = HistoryBasketDetailPage(data: data);
    } else if (activity.contains('BOLA') || activity.contains('SOCCER') || activity.contains('FOOTBALL')) {
      page = HistoryBolaDetailPage(data: data);
    } else {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_forever, color: Colors.white),
    );
  }

  Widget _buildFixedHeader(LanguageProvider lang, ThemeProvider theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
        decoration: BoxDecoration(
          color: theme.bgColor.withOpacity(0.95),
          border: Border(
            bottom: BorderSide(color: theme.textColor.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: Color(0xFF008BFF),
              size: 28,
            ),
            const SizedBox(width: 15),
            Text(
              lang.translate('history.title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
