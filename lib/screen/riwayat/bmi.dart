import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryBMIDetailPage extends StatefulWidget {
  final Map<dynamic, dynamic> data;

  const HistoryBMIDetailPage({super.key, required this.data});

  @override
  State<HistoryBMIDetailPage> createState() => _HistoryBMIDetailPageState();
}

class _HistoryBMIDetailPageState extends State<HistoryBMIDetailPage> {
  String _gender = 'MALE';

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
  }

  Future<void> _fetchUserGender() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final ref = FirebaseDatabase.instance.ref(
          "users/${user.uid}/health_data/gender",
        );
        final snapshot = await ref.get();
        if (snapshot.exists) {
          String val = snapshot.value.toString().toUpperCase();
          setState(() {
            if (val.contains("PEREMPUAN") ||
                val.contains("FEMALE") ||
                val.contains("WANITA")) {
              _gender = 'FEMALE';
            } else {
              _gender = 'MALE';
            }
          });
        }
      } catch (e) {
        debugPrint("Gagal ambil gender: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final data = widget.data;

    DateTime dt = DateTime.parse(
      data['time'] ?? DateTime.now().toIso8601String(),
    );
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    String bmiScore;
    if (data['bmi_score'] != null) {
      bmiScore = data['bmi_score'].toString();
    } else {
      String activity = data['activity']?.toString() ?? '';
      bmiScore = activity.replaceAll(RegExp(r'[^0-9.]'), '').isNotEmpty
          ? activity.replaceAll(RegExp(r'[^0-9.]'), '')
          : '0';
    }

    String weightVal = data['weight']?.toString() ?? '--';
    String heightVal = data['height']?.toString() ?? '--';
    String status = (data['status'] ?? 'Normal').toString().toUpperCase();

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            bottom:
                MediaQuery.of(context).size.height * 0.4,
            child: _buildBMIVisualization(
              status,
              weightVal,
              heightVal,
              lang,
              theme,
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.50,
            minChildSize: 0.50,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.boxColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: theme.textColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

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
                        color: theme.textColor.withOpacity(0.2),
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
                          Container(
                            width: 1,
                            height: 40,
                            color: theme.textColor.withOpacity(0.1),
                          ),
                          _buildStatItem(
                            lang.translate('history.bmiStatus'),
                            status,
                            lang.translate('history.bmiLevel'),
                            theme,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      _buildNutritionAdvice(status, theme),

                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          "Kalkulasi disesuaikan untuk ${_gender == 'MALE' ? 'Pria' : 'Wanita'}",
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.3),
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            },
          ),

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
      bodyColor = Colors.blue;
    } else if (status.contains('NORMAL') || status.contains('IDEAL')) {
      bodyColor = Colors.green;
    } else if (status.contains('OVERWEIGHT') || status.contains('GEMUK')) {
      bodyColor = Colors.orange;
    } else if (status.contains('OBESITY') || status.contains('OBES')) {
      bodyColor = Colors.red;
    } else {
      bodyColor = Colors.green;
    }

    String imageAsset = 'assets/images/bmi_character.png';
    if (_gender == 'FEMALE') {
      imageAsset = 'assets/images/bmi_character_female.png';
    }

    return Container(
      width: double.infinity,
      color: theme.bgColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30,
            top: 100,
            child: _buildRulerColumn(
              lang.translate('bmi.weight'),
              weightVal,
              "kg",
              Icons.monitor_weight_outlined,
              theme,
              min: 30,
              max: 150,
            ),
          ),
          Positioned(
            right: 30,
            top: 100,
            child: _buildRulerColumn(
              lang.translate('bmi.height'),
              heightVal,
              "cm",
              Icons.height_rounded,
              theme,
              min: 100,
              max: 250,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                imageAsset,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _gender == 'FEMALE' ? Icons.woman : Icons.man,
                    color: theme.textColor.withOpacity(0.2),
                    size: 200,
                  );
                },
              ),
              const SizedBox(height: 20),
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
                    fontSize: 14,

                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
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
    ThemeProvider theme, {
    double min = 0,
    double max = 100,
  }) {
    double val = double.tryParse(value) ?? min;
    double percentage = (val - min) / (max - min);
    if (percentage < 0) percentage = 0;
    if (percentage > 1) percentage = 1;

    return Column(
      children: [
        Icon(icon, color: theme.textColor.withOpacity(0.5), size: 22),
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
            color: theme.textColor.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          width: 12,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: theme.textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                heightFactor: percentage,
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF008BFF).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.54),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionAdvice(String status, ThemeProvider theme) {
    Map<String, dynamic> advice = _getNutritionAdvice(status);
    Color color = advice['color'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Rekomendasi Nutrisi",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            advice['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advice['desc'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (advice['foods'] as List<String>).map((food) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  food,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNutritionAdvice(String status) {
    status = status.toUpperCase();
    bool isFemale = _gender == 'FEMALE';

    if (status.contains('UNDER') || status.contains('KURANG')) {
      return {
        "title": isFemale
            ? "Booster Berat Badan Alami"
            : "Surplus Kalori & Massa Otot",
        "desc": isFemale
            ? "Fokus menaikkan lemak sehat dan protein untuk keseimbangan hormon."
            : "Tingkatkan kalori harian dengan protein tinggi untuk massa otot.",
        "foods": isFemale
            ? [
                "Alpukat 🥑",
                "Kacang Almond 🥜",
                "Smoothie Susu 🥤",
                "Ikan Salmon 🐟",
              ]
            : [
                "Daging Merah 🥩",
                "Nasi/Kentang 🍚",
                "Telur Utuh 🥚",
                "Susu Full Cream 🥛",
              ],

        "color": Colors.blue,
      };
    } else if (status.contains('OVER') || status.contains('OBES')) {
      bool isObes = status.contains('OBES');
      return {
        "title": isFemale ? "Detox & Fat Loss" : "Cutting & Pembakaran Lemak",
        "desc": isFemale
            ? "Kurangi gula tersembunyi. Fokus serat sayuran untuk pencernaan lancar."
            : "Kurangi karbohidrat simpel. Perbanyak protein lean untuk menjaga otot saat diet.",
        "foods": [
          "Sayuran Hijau 🥦",
          "Putih Telur 🥚",
          "Teh Hijau 🍵",
          "Buah Berry 🫐",
        ],

        "color": isObes ? Colors.red : Colors.orange,
      };
    } else {
      return {
        "title": "Maintain Vitalitas Tubuh",
        "desc":
            "Pertahankan pola makan seimbang. Jangan lupa hidrasi yang cukup.",
        "foods": [
          "Biji-bijian Utuh 🌾",
          "Ayam Tanpa Lemak 🍗",
          "Salad Buah 🥗",
        ],

        "color": Colors.green,
      };
    }
  }
}
