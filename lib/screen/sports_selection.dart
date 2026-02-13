import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lora_1/screen/navbar.dart';
import 'package:audioplayers/audioplayers.dart';

class SportsSelectionPage extends StatefulWidget {
  const SportsSelectionPage({super.key});

  @override
  State<SportsSelectionPage> createState() => _SportsSelectionPageState();
}

class _SportsSelectionPageState extends State<SportsSelectionPage> {
  // DATA OLAHRAGA
  final List<Map<String, String>> _sports = [
    {"name": "Basketball", "img": "assets/images/basket2.jpg"},
    {"name": "Running", "img": "assets/images/mlayu.jpg"},
    {"name": "Football", "img": "assets/images/bal.jpg"},
    {"name": "Home Workout", "img": "assets/images/wo.png"},
    {"name": "Cycling", "img": "assets/images/pedah.jpg"},
  ];

  // DATA LEVEL
  final List<Map<String, String>> _fitnessLevels = [
    {"label": "Tidak Pernah", "value": "NEVER"},
    {"label": "Lumayan Sering", "value": "SOMETIMES"},
    {"label": "Sering", "value": "OFTEN"},
    {"label": "Setiap Hari", "value": "DAILY"},
  ];

  // DATA GOAL
  final List<Map<String, String>> _fitnessGoals = [
    {"label": "Turun Berat Badan", "value": "WEIGHT_LOSS", "desc": "Fokus bakar kalori & kardio"},
    {"label": "Bentuk Otot", "value": "MUSCLE_GAIN", "desc": "Fokus kekuatan & repetisi"},
    {"label": "Jaga Kesehatan", "value": "KEEP_FIT", "desc": "Latihan seimbang & santai"},
  ];

  // DATA GENDER
  final List<Map<String, String>> _genderOptions = [
    {"label": "Laki-laki", "value": "MALE"},
    {"label": "Perempuan", "value": "FEMALE"},
  ];

  final Set<int> _selectedIndices = {};
  bool _isSaving = false;
  final AudioPlayer _pickerAudio = AudioPlayer();
  DateTime _lastPickerSoundAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _pickerSoundDebounce = Duration(milliseconds: 80);

  // STATE VARIABLES
  String _selectedLevel = "NEVER";
  String _selectedGoal = "KEEP_FIT";
  String _selectedGender = "MALE";
  int _selectedHeightCm = 170;
  int _selectedWeightKg = 65;
  int _selectedAge = 25;
  int _selectedTargetWeightKg = 60;

  @override
  void dispose() {
    _pickerAudio.dispose();
    super.dispose();
  }

  Future<void> _playPickerScrollSound() async {
    final now = DateTime.now();
    if (now.difference(_lastPickerSoundAt) < _pickerSoundDebounce) return;
    _lastPickerSoundAt = now;
    try {
      await _pickerAudio.stop();
      await _pickerAudio.play(AssetSource('sounds/click.wav'), volume: 0.4);
    } catch (_) {
      // Ignore audio glitches
    }
  }

  // --- LOGIC MODAL ---
  void _showPreferenceModal() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal satu olahraga ya Wak!")),
      );
      return;
    }

    String tempLevel = _selectedLevel;
    String tempGoal = _selectedGoal;
    String tempGender = _selectedGender;
    int tempHeight = _selectedHeightCm;
    int tempWeight = _selectedWeightKg;
    int tempAge = _selectedAge;
    int tempTargetWeight = _selectedTargetWeightKg;

    final modalPageController = PageController();
    
    // Controller Picker (FixedExtent)
    final heightController = FixedExtentScrollController(initialItem: tempHeight - 120);
    final weightController = FixedExtentScrollController(initialItem: tempWeight - 35);
    final ageController = FixedExtentScrollController(initialItem: tempAge - 13);
    final targetWeightController = FixedExtentScrollController(initialItem: tempTargetWeight - 35);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white24),
              ),
              child: PageView(
                controller: modalPageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  
                  // --- STEP 1: LEVEL ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader("Langkah 1/4", "Seberapa sering olahraga?"),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _fitnessLevels.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final level = _fitnessLevels[index];
                            final isSelected = tempLevel == level['value'];
                            return _buildOptionItem(
                              label: level['label']!,
                              isSelected: isSelected,
                              onTap: () => setModalState(() => tempLevel = level['value']!),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            modalPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: _btnStyle(),
                          child: const Text("LANJUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  // --- STEP 2: GOAL ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader("Langkah 2/4", "Apa tujuan utamamu?"),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _fitnessGoals.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final goal = _fitnessGoals[index];
                            final isSelected = tempGoal == goal['value'];
                            return _buildOptionItem(
                              label: goal['label']!,
                              subLabel: goal['desc'],
                              isSelected: isSelected,
                              onTap: () => setModalState(() => tempGoal = goal['value']!),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            modalPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: _btnStyle(),
                          child: const Text("LANJUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  // --- STEP 3: FISIK ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader("Langkah 3/4", "Isi data tubuh kamu"),
                      const SizedBox(height: 16),
                      // Gender
                      const Text("Jenis Kelamin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ..._genderOptions.map((option) {
                        final isSelected = tempGender == option['value'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildOptionItem(
                            label: option['label']!,
                            isSelected: isSelected,
                            onTap: () => setModalState(() => tempGender = option['value']!),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 10),
                      const Text("Tinggi, Berat, dan Umur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // ROW PICKER
                      Row(
                        children: [
                          Expanded(
                            child: _buildWheelPickerCard(
                              title: "Tinggi (cm)",
                              controller: heightController,
                              min: 120, max: 220,
                              onChanged: (value) => setModalState(() => tempHeight = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWheelPickerCard(
                              title: "Berat (kg)",
                              controller: weightController,
                              min: 35, max: 180,
                              onChanged: (value) => setModalState(() => tempWeight = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWheelPickerCard(
                              title: "Umur",
                              controller: ageController,
                              min: 13, max: 90,
                              onChanged: (value) => setModalState(() => tempAge = value),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            modalPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: _btnStyle(),
                          child: const Text("LANJUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  // --- STEP 4: TARGET WEIGHT ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader("Langkah 4/4", "Target berat badan kamu berapa kg?"),
                      const SizedBox(height: 20),
                      
                      _buildSinglePickerBody(
                        "Target Berat (kg)",
                        targetWeightController,
                        35, 180,
                        (value) => setModalState(() => tempTargetWeight = value),
                      ),
                      
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedLevel = tempLevel;
                              _selectedGoal = tempGoal;
                              _selectedGender = tempGender;
                              _selectedHeightCm = tempHeight;
                              _selectedWeightKg = tempWeight;
                              _selectedAge = tempAge;
                              _selectedTargetWeightKg = tempTargetWeight;
                            });
                            Navigator.pop(context);
                            _handleStart();
                          },
                          style: _btnStyle(),
                          child: const Text("MULAI DASHBOARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      modalPageController.dispose();
      heightController.dispose();
      weightController.dispose();
      ageController.dispose();
      targetWeightController.dispose();
    });
  }

  // --- WIDGET HELPER (FIXED) ---

  // ✅ PERBAIKAN UTAMA: Tambahkan height fix di Container
  Widget _buildWheelPickerCard({
    required String title,
    required FixedExtentScrollController controller,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 160, // 🔥 WAJIB ADA BIAR TIDAK CRASH (EXPANDED ERROR)
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 34,
                  perspective: 0.005,
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(parent: ClampingScrollPhysics()), // Anti-Bouncing
                  onSelectedItemChanged: (index) {
                    onChanged(min + index);
                    _playPickerScrollSound();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: max - min + 1,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${min + index}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ PERBAIKAN UTAMA: Tambahkan height fix di Container
  Widget _buildSinglePickerBody(
    String label,
    FixedExtentScrollController controller,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      height: 250, // 🔥 WAJIB ADA BIAR TIDAK CRASH
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: const Color(0xFF008BFF).withOpacity(0.3), width: 1.5),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 44,
                  perspective: 0.005,
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(parent: ClampingScrollPhysics()), // Anti-Bouncing
                  onSelectedItemChanged: (index) {
                    onChanged(min + index);
                    _playPickerScrollSound();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: max - min + 1,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${min + index}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalHeader(String step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          step,
          style: const TextStyle(
            color: Color(0xFF5EEAD4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required String label,
    String? subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008BFF).withOpacity(0.15)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF008BFF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF008BFF) : Colors.white24,
              size: 24,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF008BFF) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF008BFF),
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    );
  }

  Future<void> _handleStart() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_fitness_level', _selectedLevel);
      await prefs.setString('user_fitness_goal', _selectedGoal);
      await prefs.setString('user_gender', _selectedGender);
      await prefs.setInt('user_height_cm', _selectedHeightCm);
      await prefs.setInt('user_weight_kg', _selectedWeightKg);
      await prefs.setInt('user_age', _selectedAge);
      await prefs.setInt('user_target_weight_kg', _selectedTargetWeightKg);

      if (user != null) {
        final selectedNames =
            _selectedIndices.map((i) => _sports[i]['name'] ?? "Unknown").toList();
        final Map<String, bool> sportsForMap = {};
        for (final name in selectedNames) {
          var key = name.toUpperCase();
          if (key == "RUNNING") key = "LARI";
          if (key == "CYCLING") key = "SEPEDA";
          if (key == "FOOTBALL") key = "BOLA";
          if (key == "BASKETBALL") key = "BASKET";
          sportsForMap[key] = true;
        }

        final genderLabel = _selectedGender == "MALE" ? "Laki-laki" : "Perempuan";

        await FirebaseDatabase.instance.ref("users/${user.uid}").update({
          "sports": sportsForMap,
          "favorite_sports": selectedNames,
          "fitness_level": _selectedLevel,
          "fitness_goal": _selectedGoal,
          "onboarding_completed": true,
          "health_data": {
            "height": _selectedHeightCm,
            "weight": _selectedWeightKg,
            "gender": genderLabel,
            "age": _selectedAge,
            "target_weight": _selectedTargetWeightKg,
          },
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Navbar()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error save: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 30, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Olahraga",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pilih jenis olahraga yang kamu suka",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.05, 0.95, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  itemCount: _sports.length,
                  physics: const ClampingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndices.contains(index);
                    return GestureDetector(
                      onTap: () => setState(
                        () => isSelected
                            ? _selectedIndices.remove(index)
                            : _selectedIndices.add(index),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.grey[900]!.withOpacity(0.6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white10,
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  _sports[index]['img']!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                  errorBuilder: (ctx, err, stack) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [
                                            Colors.white.withOpacity(0.1),
                                            Colors.transparent,
                                          ]
                                        : [
                                            Colors.black.withOpacity(0.9),
                                            Colors.transparent,
                                          ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _sports[index]['name']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white24,
                                      size: 30,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _showPreferenceModal,
                  style: _btnStyle(),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "SELANJUTNYA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}