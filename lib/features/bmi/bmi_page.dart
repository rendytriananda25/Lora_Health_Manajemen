import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

// Clean Code: Import Widgets Terpisah
import 'widgets/glass_card.dart';
import 'widgets/human_painter.dart';
import 'widgets/gauge_painter.dart';

class BMIPage extends StatefulWidget {
  const BMIPage({super.key});

  @override
  State<BMIPage> createState() => _BMIPageState();
}

class _BMIPageState extends State<BMIPage> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ✅ VARIABEL ANTI MACET
  DateTime _lastPlayTime = DateTime.now();

  int _currentPage = 0;
  int _height = 170;
  int _weight = 60;
  int _age = 24;

  double _bmiResult = 0;
  String _bmiStatus = "";
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() async {
    // Mode Low Latency wajib biar responsif
    await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  // ✅ FUNGSI SUARA "TIK-TIK" (FIXED & TESTED)
  void _playPremiumTick() async {
    final now = DateTime.now();

    // Rem dikit (50ms) biar gak "keselek" kalau scroll super ngebut
    if (now.difference(_lastPlayTime).inMilliseconds < 50) {
      return;
    }
    _lastPlayTime = now;

    try {
      // 1. Stop paksa biar suara sebelumnya kepotong (reset ke 0)
      await _audioPlayer.stop();

      // 2. Play ulang dari awal (Gunakan PLAY, bukan RESUME)
      await _audioPlayer.play(AssetSource('sounds/click.wav'));

      // 3. Getaran halus biar kerasa fisik
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  Future<void> _saveToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final dbRef = FirebaseDatabase.instance.ref(
          "users/${user.uid}/history",
        );
        await dbRef.push().set({
          'activity': "Cek BMI: ${_bmiResult.toStringAsFixed(1)}",
          'time': DateTime.now().toIso8601String(),
          'status': _bmiStatus,
          'weight': _weight,
          'height': _height,
          'bmi_score': _bmiResult.toStringAsFixed(1),
        });
      } catch (e) {
        debugPrint("Gagal simpan history: $e");
      }
    }
  }

  void _calculateBMI() {
    double heightInMeter = _height / 100;
    _bmiResult = _weight / (heightInMeter * heightInMeter);

    if (_bmiResult < 18.5) {
      _bmiStatus = "Underweight";
      _statusColor = Colors.blueAccent;
    } else if (_bmiResult < 25) {
      _bmiStatus = "Normal";
      _statusColor = const Color(0xFF008BFF);
    } else if (_bmiResult < 30) {
      _bmiStatus = "Overweight";
      _statusColor = Colors.orange;
    } else {
      _bmiStatus = "Obesity";
      _statusColor = Colors.redAccent;
    }

    setState(() {});
    _saveToHistory();
  }

  void _nextPage() {
    HapticFeedback.mediumImpact();
    // Bunyi tombol Next (pasti bunyi)
    _audioPlayer.stop();
    _audioPlayer.play(AssetSource('sounds/click.wav'));

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
      if (_currentPage == 1) _calculateBMI();
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agar halaman ikut rebuild saat bahasa berubah
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
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
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _prevPage,
                      icon: Icon(Icons.arrow_back_ios, color: theme.textColor),
                    )
                  else
                    const SizedBox(width: 40),
                  Text(
                    _currentPage == 0
                        ? lang.translate('bmi.selectHeight')
                        : _currentPage == 1
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
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHeightPage(lang, theme),
                  _buildWeightPage(lang, theme),
                  _buildResultPage(lang, theme),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- HALAMAN 1: TINGGI BADAN ---
  Widget _buildHeightPage(LanguageProvider lang, ThemeProvider theme) {
    double normalizedHeight = (_height - 100) / 150;
    if (normalizedHeight < 0) normalizedHeight = 0;
    if (normalizedHeight > 1) normalizedHeight = 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(5),
          child: _buildToggleBtn("Centimeter", true),
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
                  initialItem: 250 - _height,
                ),
                onSelectedItemChanged: (index) {
                  // ✅ PANGGIL FUNGSI FIX DISINI
                  _playPremiumTick();
                  setState(() => _height = 250 - index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 151,
                  builder: (context, index) {
                    int value = 250 - index;
                    bool isSelected = value == _height;
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
        _buildNextButton(lang.translate('bmi.next')),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- HALAMAN 2: BERAT BADAN ---
  Widget _buildWeightPage(LanguageProvider lang, ThemeProvider theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(5),
          child: _buildToggleBtn("Kilogram", true),
        ),
        const Spacer(),
        SizedBox(
          height: 250,
          width: 300,
          child: CustomPaint(
            painter: GaugePainter(
              value: _weight.toDouble(),
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
                    "$_weight KG",
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
              value: _weight.toDouble(),
              min: 30,
              max: 150,
              onChanged: (val) {
                if (val.toInt() != _weight) {
                  // ✅ PANGGIL FUNGSI FIX DISINI
                  _playPremiumTick();
                }
                setState(() => _weight = val.toInt());
              },
            ),
          ),
        ),
        const Spacer(),
        _buildNextButton(lang.translate('bmi.calculate')),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- HALAMAN 3: RESULT ---
  Widget _buildResultPage(LanguageProvider lang, ThemeProvider theme) {
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
                value: _bmiResult / 40,
                strokeWidth: 20,
                backgroundColor: theme.textColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              children: [
                Text(
                  _bmiResult.toStringAsFixed(1),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _bmiStatus.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
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
            _buildStatBox(lang.translate('bmi.age'), "$_age", theme),
            Container(
              width: 1,
              height: 40,
              color: theme.textColor.withOpacity(0.24),
            ),
            _buildStatBox(lang.translate('bmi.height'), "$_height", theme),
            Container(
              width: 1,
              height: 40,
              color: theme.textColor.withOpacity(0.24),
            ),
            _buildStatBox(lang.translate('bmi.weight'), "$_weight", theme),
          ],
        ),
        const Spacer(),
        _buildNextButton(
          lang.translate('bmi.recalculate'),
          onTap: () {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
            setState(() {
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildToggleBtn(String text, bool isActive) {
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

  Widget _buildNextButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? _nextPage,
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
