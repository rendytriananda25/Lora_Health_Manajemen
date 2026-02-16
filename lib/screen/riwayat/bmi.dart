import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryBMIDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryBMIDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    // Format tanggal
    DateTime dt = DateTime.parse(
      data['time'] ?? DateTime.now().toIso8601String(),
    );
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    // ✅ Parse BMI score dari field baru ATAU extract dari activity string (backward compat)
    String bmiScore;
    if (data['bmi_score'] != null) {
      bmiScore = data['bmi_score'].toString();
    } else {
      // Fallback: parse dari "Cek BMI: 22.5"
      String activity = data['activity']?.toString() ?? '';
      bmiScore = activity.replaceAll(RegExp(r'[^0-9.]'), '').isNotEmpty
          ? activity.replaceAll(RegExp(r'[^0-9.]'), '')
          : '0';
    }

    // ✅ Parse height & weight dari data (baru disimpan setelah fix)
    String weightVal = data['weight']?.toString() ?? '--';
    String heightVal = data['height']?.toString() ?? '--';
    String status = (data['status'] ?? 'Normal').toString().toUpperCase();

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. VISUALISASI KARAKTER & ANGKA TINGGI/BERAT
              Expanded(
                flex: 4,
                child: _buildBMIVisualization(
                  status,
                  weightVal,
                  heightVal,
                  lang,
                  theme,
                ),
              ),

              // 2. PANEL STATISTIK BAWAH
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: theme.boxColor.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    border: Border.all(color: theme.textColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('history.bmiResultTitle'),
                        style: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(
                        color: theme.textColor.withOpacity(0.1),
                        height: 40,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            lang.translate('history.bmiScore'),
                            bmiScore,
                            lang.translate('history.bmiIndex'),
                            theme,
                          ),
                          _buildStatItem(
                            lang.translate('history.bmiStatus'),
                            status,
                            lang.translate('history.bmiLevel'),
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tombol Kembali
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: theme.boxColor.withOpacity(0.5),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: theme.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIVisualization(
    String status,
    String weightVal,
    String heightVal,
    LanguageProvider lang,
    ThemeProvider theme,
  ) {
    Color bodyColor;
    if (status.contains('UNDERWEIGHT') || status.contains('KURANG')) {
      bodyColor = Colors.lightBlueAccent;
    } else if (status.contains('NORMAL')) {
      bodyColor = const Color(0xFF5EEAD4);
    } else if (status.contains('OVERWEIGHT') || status.contains('OVER')) {
      bodyColor = Colors.orangeAccent;
    } else if (status.contains('OBESITY') || status.contains('OBES')) {
      bodyColor = Colors.redAccent;
    } else {
      bodyColor = const Color(0xFF5EEAD4);
    }

    return Container(
      width: double.infinity,
      color: theme.bgColor, // Adaptive Background
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 50,
            bottom: 60,
            top: 100,
            child: _buildRulerColumn(
              lang.translate('bmi.weight'),
              weightVal,
              "kg",
              Icons.monitor_weight_outlined,
              theme,
            ),
          ),
          Positioned(
            right: 50,
            bottom: 60,
            top: 100,
            child: _buildRulerColumn(
              lang.translate('bmi.height'),
              heightVal,
              "cm",
              Icons.height_rounded,
              theme,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Use ColorFiltered or Icon if image doesn't support theme,
              // but image is likely PNG. Providing a placeholder logic
              Image.asset(
                'assets/images/bmi_character.png',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: theme.textColor.withOpacity(0.24),
                    size: 200,
                  );
                },
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bodyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bodyColor.withOpacity(0.2)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulerColumn(
    String label,
    String value,
    String unit,
    IconData icon,
    ThemeProvider theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.textColor.withOpacity(0.24), size: 22),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.38),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Container(
            width: 12,
            decoration: BoxDecoration(
              color: theme.textColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                12,
                (index) => Container(
                  width: index % 4 == 0 ? 10 : 5,
                  height: 1.5,
                  color: theme.textColor.withOpacity(0.12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.24),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    ThemeProvider theme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.54),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
