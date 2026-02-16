import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class GlassControlPanel extends StatelessWidget {
  final String selectedSport;
  final String currentTemp;
  final bool isRecording;
  final VoidCallback onToggleRecord;
  final ValueNotifier<int> secondsNotifier;
  final ValueNotifier<double> distanceNotifier;

  const GlassControlPanel({
    super.key,
    required this.selectedSport,
    required this.currentTemp,
    required this.isRecording,
    required this.onToggleRecord,
    required this.secondsNotifier,
    required this.distanceNotifier,
  });

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.boxColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedSport,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${currentTemp}°C",
                style: TextStyle(color: theme.textColor, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: distanceNotifier,
                builder: (context, val, _) => _buildStat(
                  val.toStringAsFixed(2),
                  lang.translate('map.km'),
                  theme,
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: secondsNotifier,
                builder: (context, val, _) => _buildStat(
                  _formatTime(val),
                  lang.translate('map.time'),
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: onToggleRecord,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isRecording
                    ? const Color.fromARGB(255, 255, 0, 0)
                    : theme
                          .textColor, // Reverse color for button (Black on White bg, White on Dark bg)
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  isRecording
                      ? lang.translate('map.stop')
                      : lang.translate('map.start'),
                  style: TextStyle(
                    color: isRecording
                        ? Colors.white
                        : theme.boxColor, // Contrast text
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label, ThemeProvider theme) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
