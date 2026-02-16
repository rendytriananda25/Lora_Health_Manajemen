import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryCard extends StatelessWidget {
  final Map data;
  final VoidCallback onTap;

  const HistoryCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final String activity = (data['activity'] ?? 'Aktivitas')
        .toString()
        .toUpperCase();
    final String timeStr = data['time'] ?? '';
    final String type = (data['type'] ?? '').toString().toUpperCase();

    // Format Tanggal
    String formattedDate = "N/A";
    if (timeStr.isNotEmpty) {
      DateTime dt = DateTime.parse(timeStr);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }

    // Tentukan Icon
    IconData activityIcon = Icons.fitness_center;
    if (type == 'TRACKING' ||
        activity.contains('LARI') ||
        activity.contains('SEPEDA')) {
      activityIcon = activity.contains('SEPEDA')
          ? Icons.directions_bike
          : Icons.directions_run;
    } else if (type == 'BMI' || activity.contains('BMI')) {
      activityIcon = Icons.monitor_weight_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.boxColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.textColor.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Sisi Kiri: Icon & Info Utama
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Icon(activityIcon, color: const Color(0xFF008BFF), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['activity'] ?? 'Aktivitas',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.54),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sisi Kanan: Statistik (Panggil Widget Kecil di bawah)
            Expanded(
              flex: 5,
              child: (type == 'BMI' || activity.contains('BMI'))
                  ? _buildBMIStats(data, theme)
                  : _buildTrackingStats(data, theme),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.textColor.withOpacity(0.24),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // Widget Statistik Tracking (Dgn Perbaikan Overflow)
  Widget _buildTrackingStats(Map data, ThemeProvider theme) {
    String distance = "0";
    if (data['distance_km'] != null) {
      try {
        distance = double.parse(
          data['distance_km'].toString(),
        ).toStringAsFixed(2);
      } catch (_) {}
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildStatItem(distance, "km", theme),
        const SizedBox(width: 12),
        _buildStatItem(data['calories']?.toString() ?? "0", "kcal", theme),
      ],
    );
  }

  Widget _buildBMIStats(Map data, ThemeProvider theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          data['status'] ?? "N/A",
          style: const TextStyle(
            color: Color(0xFF5EEAD4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String unit, ThemeProvider theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.54),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
