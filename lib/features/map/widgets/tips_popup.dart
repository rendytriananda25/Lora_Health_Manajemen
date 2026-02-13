import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

class TipsPopup extends StatelessWidget {
  final bool showTips;
  final String selectedSport;
  final String targetText; // ✅ Contoh: "10 KM" atau "15-25 Menit"
  final String weatherAdvice; // ✅ Contoh: "Bahaya Heat Exhaustion"
  final VoidCallback onToggle;

  const TipsPopup({
    super.key,
    required this.showTips,
    required this.selectedSport,
    required this.targetText,
    required this.weatherAdvice,
    required this.onToggle,
  });

  IconData _getIconForSport(String sport) {
    switch (sport.toUpperCase()) {
      case "LARI":
        return Icons.directions_run;
      case "SEPEDA":
        return Icons.directions_bike;
      case "HOME WORKOUT":
        return Icons.fitness_center;
      case "BASKET":
        return Icons.sports_basketball;
      case "SEPAK BOLA":
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Stack(
      children: [
        Positioned(
          top: 120,
          left: 20,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                showTips ? Icons.close : Icons.info_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        if (showTips)
          Positioned(
            top: 120,
            left: 80,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForSport(selectedSport),
                        color: const Color(0xFF008BFF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.translate('map.targetToday').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ✅ Tampilkan Target (Misal: 10 KM) secara menonjol
                  Text(
                    targetText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  // ✅ Tampilkan Saran Cuaca dari JSON
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orangeAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          weatherAdvice,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
