import 'package:flutter/material.dart';
import 'package:lora_1/features/map/widgets/exercise_card.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'exercise_card.dart';

class TimerBackground extends StatefulWidget {
  final String selectedSport;
  final bool isRecording;
  final ValueNotifier<int> secondsNotifier;
  final List<Map<String, dynamic>> exercises;
  final Function(String name, String result) onCompleteExercise;
  final Function(int index) onSkipExercise;
  final VoidCallback onStop;
  final VoidCallback onStart;

  const TimerBackground({
    super.key,
    required this.selectedSport,
    required this.isRecording,
    required this.secondsNotifier,
    required this.exercises,
    required this.onStop,
    required this.onStart,
    required this.onCompleteExercise,
    required this.onSkipExercise,
  });

  @override
  State<TimerBackground> createState() => _TimerBackgroundState();
}

class _TimerBackgroundState extends State<TimerBackground> {
  // ✅ PERBAIKAN: Perkecil viewportFraction agar card tidak terlalu raksasa
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentExerciseIndex = 0;

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _handleComplete(String name, String result) {
    widget.onCompleteExercise(name, result);
    final activeExercises = widget.exercises
        .where((e) => e['isSelected'] == true)
        .toList();

    if (_currentExerciseIndex < activeExercises.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises
        .where((e) => e['isSelected'] == true)
        .toList();
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(
            height: 70,
          ), // ✅ Atur jarak atas agar tidak mepet status bar

          ValueListenableBuilder<int>(
            valueListenable: widget.secondsNotifier,
            builder: (context, val, _) => Text(
              _formatTime(val),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            lang.translate('map.activeSession'),
            style: const TextStyle(
              color: Colors.white38,
              letterSpacing: 4,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 15), // ✅ Perkecil jarak antar elemen
          // ✅ LOGIC TAMPILAN
          Expanded(
            child: widget.isRecording && widget.selectedSport == "HOME WORKOUT"
                ? (filteredExercises.isEmpty
                      ? Center(
                          child: Text(
                            lang.translate('map.noExerciseSelected'),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: filteredExercises.length,
                                onPageChanged: (index) => setState(
                                  () => _currentExerciseIndex = index,
                                ),
                                itemBuilder: (context, index) {
                                  return ExerciseCard(
                                    data: filteredExercises[index],
                                    isActive: index == _currentExerciseIndex,
                                    onComplete: _handleComplete,
                                  );
                                },
                              ),
                            ),
                            // ✅ PENTING: Tambahkan Spacer/Padding bawah agar tombol di Card tidak tertutup Navbar
                            const SizedBox(height: 100),
                          ],
                        ))
                : _buildPreStartChecklist(lang),
          ),

          if (!widget.isRecording)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                40,
                0,
                40,
                120,
              ), // ✅ Padding bawah untuk tombol START
              child: GestureDetector(
                onTap: widget.onStart,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      lang.translate('map.startSession'),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreStartChecklist(LanguageProvider lang) {
    return Column(
      children: [
        Text(
          lang.translate('map.chooseExercise'),
          style: const TextStyle(
            color: Color(0xFF5EEAD4),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: widget.exercises.length,
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              100,
            ), // ✅ Beri padding bawah di list agar tidak ketutup navbar
            itemBuilder: (context, i) {
              final ex = widget.exercises[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: CheckboxListTile(
                  value: ex['isSelected'] ?? true,
                  onChanged: (val) => setState(() => ex['isSelected'] = val),
                  title: Text(
                    ex['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${lang.translate('map.target')}: ${ex['target']}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  secondary: Icon(
                    ex['icon'] ?? Icons.fitness_center,
                    color: const Color(0xFF5EEAD4),
                  ),
                  activeColor: const Color(0xFF5EEAD4),
                  checkColor: Colors.black,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
