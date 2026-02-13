import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

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
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedSport,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${currentTemp}°C",
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: secondsNotifier,
                builder: (context, val, _) =>
                    _buildStat(_formatTime(val), lang.translate('map.time')),
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
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  isRecording
                      ? lang.translate('map.stop')
                      : lang.translate('map.start'),
                  style: TextStyle(
                    color: isRecording ? Colors.white : Colors.black,
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

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
