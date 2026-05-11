import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryBasketDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryBasketDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    DateTime dt = DateTime.parse(
      data['time'] ?? DateTime.now().toIso8601String(),
    );
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Detail Basket",
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['activity'] ?? 'Aktivitas Basket',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.54),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: theme.textColor.withOpacity(0.24)),
            const SizedBox(height: 20),
            _buildStat(
              "Kalori Terbakar",
              "${data['calories'] ?? 0} kcal",
              theme,
            ),
            _buildStat(
              "Durasi",
              "${((data['duration_sec'] ?? 0) / 60).round()} menit",
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.70),
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
