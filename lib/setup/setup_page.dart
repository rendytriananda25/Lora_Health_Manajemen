import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/setup/data/setup_constants.dart';
import 'package:lora_1/setup/service/setup_service.dart';
import 'package:lora_1/setup/views/sport_selection_view.dart';
import 'package:lora_1/setup/widgets/setup_option_card.dart';
import 'package:lora_1/setup/widgets/wheel_picker_card.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  final Set<int> _selectedIndices = {};
  String _level = "NEVER";
  String _goal = "KEEP_FIT";
  String _gender = "MALE";
  int _height = 170;
  int _weight = 65;
  int _age = 25;
  int _frequency = 1;
  int _targetWeight = 60;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal satu olahraga!")),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishSetup() async {
    setState(() => _isSaving = true);
    await SetupService.saveAndStart(
      context,
      selectedIndices: _selectedIndices,
      level: _level,
      goal: _goal,
      gender: _gender,
      height: _height,
      weight: _weight,
      age: _age,
      frequency: _frequency,
      targetWeight: _targetWeight,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(theme),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _buildSportSelectionStep(theme),
                  _buildLevelStep(theme),
                  _buildGoalStep(theme),
                  _buildBodyDataStep(theme),
                  _buildFrequencyStep(theme),
                  if (_goal != "KEEP_FIT") _buildTargetWeightStep(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeProvider theme) {
    final int totalSteps = _goal == "KEEP_FIT" ? 5 : 6;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF008BFF)
                    : theme.textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContainer({
    required String step,
    required String title,
    required List<Widget> children,
    required VoidCallback onNext,
    required ThemeProvider theme,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008BFF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      isLast ? "MULAI SEKARANG ->" : "LANJUT",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelectionStep(ThemeProvider theme) {
    return Column(
      children: [
        Expanded(
          child: SportSelectionView(
            selectedIndices: _selectedIndices,
            onToggle: (idx) {
              setState(() {
                if (_selectedIndices.contains(idx)) {
                  _selectedIndices.remove(idx);
                } else {
                  _selectedIndices.add(idx);
                }
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008BFF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                "SELANJUTNYA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelStep(ThemeProvider theme) {
    final int total = _goal == "KEEP_FIT" ? 4 : 5;
    return _buildStepContainer(
      step: "Langkah 1/$total",
      title: "Seberapa sering kamu olahraga?",
      onNext: _nextStep,
      theme: theme,
      children: SetupConstants.fitnessLevels.map((level) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SetupOptionCard(
            label: level['label']!,
            isSelected: _level == level['value'],
            onTap: () => setState(() => _level = level['value']!),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalStep(ThemeProvider theme) {
    final int total = _goal == "KEEP_FIT" ? 4 : 5;
    return _buildStepContainer(
      step: "Langkah 2/$total",
      title: "Apa tujuan utamamu?",
      onNext: _nextStep,
      theme: theme,
      children: SetupConstants.fitnessGoals.map((g) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SetupOptionCard(
            label: g['label']!,
            subLabel: g['desc'],
            isSelected: _goal == g['value'],
            onTap: () => setState(() => _goal = g['value']!),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBodyDataStep(ThemeProvider theme) {
    final int total = _goal == "KEEP_FIT" ? 4 : 5;
    return _buildStepContainer(
      step: "Langkah 3/$total",
      title: "Data Tubuh Kamu",
      onNext: _nextStep,
      theme: theme,
      children: [
        Text(
          "Jenis Kelamin",
          style: TextStyle(
            color: theme.textColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: SetupConstants.genderOptions.map((opt) {
            final isSelected = _gender == opt['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SetupOptionCard(
                  label: opt['label']!,
                  isSelected: isSelected,
                  onTap: () => setState(() => _gender = opt['value']!),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          "Detail Fisik",
          style: TextStyle(
            color: theme.textColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: WheelPickerCard(
                title: "Tinggi (cm)",
                min: 120,
                max: 220,
                initialValue: _height,
                onChanged: (val) => setState(() => _height = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WheelPickerCard(
                title: "Berat (kg)",
                min: 35,
                max: 180,
                initialValue: _weight,
                onChanged: (val) => setState(() => _weight = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WheelPickerCard(
                title: "Umur",
                min: 13,
                max: 80,
                initialValue: _age,
                onChanged: (val) => setState(() => _age = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyStep(ThemeProvider theme) {
    final bool isKeepFit = _goal == "KEEP_FIT";
    final int total = isKeepFit ? 4 : 5;
    return _buildStepContainer(
      step: "Langkah 4/$total",
      title: "Frekuensi Latihan Harian",
      onNext: isKeepFit ? _finishSetup : _nextStep,
      isLast: isKeepFit,
      theme: theme,
      children: [
        SetupOptionCard(
          label: "1x Sehari (Pagi/Sore)",
          subLabel: "Cocok untuk pemula atau sibuk kerja.",
          isSelected: _frequency == 1,
          onTap: () => setState(() => _frequency = 1),
        ),
        const SizedBox(height: 12),
        SetupOptionCard(
          label: "2x Sehari (Pagi & Sore)",
          subLabel: "Untuk hasil maksimal & atlet profesional.",
          isSelected: _frequency == 2,
          onTap: () => setState(() => _frequency = 2),
        ),
      ],
    );
  }

  Widget _buildTargetWeightStep(ThemeProvider theme) {
    final int total = 5;
    return _buildStepContainer(
      step: "Langkah 5/$total",
      title: "Target Berat Badan",
      onNext: _finishSetup,
      isLast: true,
      theme: theme,
      children: [
        const SizedBox(height: 20),
        Center(
          child: WheelPickerCard(
            title: "Target Berat (Kg)",
            min: 35,
            max: 150,
            initialValue: _targetWeight,
            onChanged: (val) => setState(() => _targetWeight = val),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Kami akan menyesuaikan rencana latihan dan nutrisi berdasarkan target ini.",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.textColor.withOpacity(0.54)),
        ),
      ],
    );
  }
}
