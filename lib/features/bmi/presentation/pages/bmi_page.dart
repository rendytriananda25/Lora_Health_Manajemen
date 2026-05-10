import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/bmi/presentation/providers/bmi_provider.dart';

// Clean Code: Import Widgets Terpisah
import '../../widgets/glass_card.dart';
import '../../widgets/human_painter.dart';
import '../../widgets/gauge_painter.dart';

class BMIPage extends StatelessWidget {
  const BMIPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Agar halaman ikut rebuild saat bahasa berubah
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    
    // Gunakan Consumer untuk listen perubahan BMI State
    return Consumer<BmiProvider>(
      builder: (context, bmiProvider, child) {
        return Scaffold(
          backgroundColor: theme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (bmiProvider.currentPage > 0)
                        IconButton(
                          onPressed: bmiProvider.prevPage,
                          icon: Icon(Icons.arrow_back_ios, color: theme.textColor),
                        )
                      else
                        const SizedBox(width: 40),
                      Text(
                        bmiProvider.currentPage == 0
                            ? lang.translate('bmi.selectHeight')
                            : bmiProvider.currentPage == 1
                                ? lang.translate('bmi.selectWeight')
                                : lang.translate('bmi.result'),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: bmiProvider.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildHeightPage(context, lang, theme, bmiProvider),
                      _buildWeightPage(context, lang, theme, bmiProvider),
                      _buildResultPage(context, lang, theme, bmiProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HALAMAN 1: TINGGI BADAN ---
  Widget _buildHeightPage(
      BuildContext context, LanguageProvider lang, ThemeProvider theme, BmiProvider bmiProvider) {
    double normalizedHeight = (bmiProvider.height - 100) / 150;
    if (normalizedHeight < 0) normalizedHeight = 0;
    if (normalizedHeight > 1) normalizedHeight = 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(5),
          child: _buildToggleBtn(context, "Centimeter", true),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 400,
              width: 100,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                  initialItem: 250 - bmiProvider.height,
                ),
                onSelectedItemChanged: (index) {
                  bmiProvider.playPremiumTick();
                  bmiProvider.setHeight(250 - index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 151,
                  builder: (context, index) {
                    int value = 250 - index;
                    bool isSelected = value == bmiProvider.height;
                    return Center(
                      child: Row(
                        children: [
                          Container(
                            height: 2,
                            width: isSelected ? 40 : 20,
                            color: isSelected
                                ? const Color(0xFF008BFF)
                                : theme.textColor.withOpacity(0.24),
                          ),
                          const SizedBox(width: 10),
                          if (isSelected || value % 10 == 0)
                            Text(
                              "$value",
                              style: TextStyle(
                                color: isSelected
                                    ? theme.textColor
                                    : theme.textColor.withOpacity(0.24),
                                fontSize: isSelected ? 24 : 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              height: 400,
              width: 150,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      size: const Size(120, 350),
                      painter: HumanPainter(color: theme.textColor),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    height: 150 + (normalizedHeight * 200),
                    width: 120,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 100,
                        height: 300,
                        child: CustomPaint(
                          painter: HumanPainter(color: const Color(0xFF008BFF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildNextButton(lang.translate('bmi.next'), onTap: bmiProvider.nextPage),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- HALAMAN 2: BERAT BADAN ---
  Widget _buildWeightPage(
      BuildContext context, LanguageProvider lang, ThemeProvider theme, BmiProvider bmiProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(5),
          child: _buildToggleBtn(context, "Kilogram", true),
        ),
        const Spacer(),
        SizedBox(
          height: 250,
          width: 300,
          child: CustomPaint(
            painter: GaugePainter(
              value: bmiProvider.weight.toDouble(),
              min: 30,
              max: 150,
              bgColor: theme.textColor.withOpacity(0.1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    "${bmiProvider.weight} KG",
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF008BFF),
              thumbColor: Colors.white,
              trackHeight: 10,
            ),
            child: Slider(
              value: bmiProvider.weight.toDouble(),
              min: 30,
              max: 150,
              onChanged: (val) {
                if (val.toInt() != bmiProvider.weight) {
                  bmiProvider.playPremiumTick();
                }
                bmiProvider.setWeight(val.toInt());
              },
            ),
          ),
        ),
        const Spacer(),
        _buildNextButton(lang.translate('bmi.calculate'), onTap: bmiProvider.nextPage),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- HALAMAN 3: RESULT ---
  Widget _buildResultPage(
      BuildContext context, LanguageProvider lang, ThemeProvider theme, BmiProvider bmiProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: bmiProvider.bmiResult / 40,
                strokeWidth: 20,
                backgroundColor: theme.textColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(bmiProvider.statusColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              children: [
                Text(
                  bmiProvider.bmiResult.toStringAsFixed(1),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bmiProvider.bmiStatus.toUpperCase(),
                  style: TextStyle(
                    color: bmiProvider.statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox(lang.translate('bmi.age'), "${bmiProvider.age}", theme),
            Container(
              width: 1,
              height: 40,
              color: theme.textColor.withOpacity(0.24),
            ),
            _buildStatBox(lang.translate('bmi.height'), "${bmiProvider.height}", theme),
            Container(
              width: 1,
              height: 40,
              color: theme.textColor.withOpacity(0.24),
            ),
            _buildStatBox(lang.translate('bmi.weight'), "${bmiProvider.weight}", theme),
          ],
        ),
        const Spacer(),
        _buildNextButton(
          lang.translate('bmi.recalculate'),
          onTap: bmiProvider.reset,
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildToggleBtn(BuildContext context, String text, bool isActive) {
    final theme = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF008BFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : theme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNextButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF008BFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF008BFF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, ThemeProvider theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.38),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
