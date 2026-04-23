import 'package:flutter/material.dart';
import 'package:lora_1/features/map/widgets/exercise_card.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class TimerBackground extends StatefulWidget {
  final String selectedSport;
  final bool isRecording;
  final ValueNotifier<int> secondsNotifier;
  final List<Map<String, dynamic>> exercises;
  final Function(String name, String result) onCompleteExercise;
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
  });

  @override
  State<TimerBackground> createState() => _TimerBackgroundState();
}

class _TimerBackgroundState extends State<TimerBackground> {
  late final PageController _pageController;
  int _currentExerciseIndex = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);

    _pageController.addListener(() {
      if (mounted && _pageController.position.haveDimensions) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // 🔥 LOGIKA "SELESAI SESI" — User WAJIB ikuti semua gerakan berurutan
  void _handleComplete(String name, String result) {
    // 1. Simpan hasil latihannya
    widget.onCompleteExercise(name, result);

    // 2. Cek masih ada exercise selanjutnya?
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      // ✅ GESER KE KARTU SELANJUTNYA SECARA OTOMATIS
      _pageController.animateToPage(
        _currentExerciseIndex + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Semua exercise selesai → Stop sesi
      widget.onStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // Navbar space dinamis berdasarkan tinggi layar
    final navbarSpace = (screenHeight * 0.14).clamp(90.0, 130.0);
    // Top spacing dinamis (status bar + timer area)
    final topSpace = (screenHeight * 0.09).clamp(50.0, 80.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.bgColor,
      child: Column(
        children: [
          SizedBox(height: topSpace),
          ValueListenableBuilder<int>(
            valueListenable: widget.secondsNotifier,
            builder: (context, val, _) => Text(
              _formatTime(val),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            lang.translate('map.activeSession'),
            style: TextStyle(
              color: theme.textColor.withOpacity(0.38),
              letterSpacing: 4,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: widget.isRecording
                ? (widget.exercises.isEmpty
                      ? Center(
                          child: Text(
                            lang.translate('map.noExerciseSelected'),
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.54),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                physics:
                                    const _ForwardBlockingScrollPhysics(),
                                itemCount: widget.exercises.length,
                                onPageChanged: (index) {
                                  setState(() => _currentExerciseIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  double difference = index - _pageOffset;
                                  double scale =
                                      1.0 -
                                      (0.15 * difference.abs()).clamp(0.0, 1.0);
                                  double opacity =
                                      1.0 -
                                      (0.6 * difference.abs()).clamp(0.0, 1.0);

                                  return Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: ExerciseCard(
                                        key: ValueKey(
                                          "${widget.exercises[index]['name']}_$index",
                                        ),
                                        data: widget.exercises[index],
                                        isActive:
                                            index == _currentExerciseIndex,
                                        isLastExercise:
                                            index ==
                                            widget.exercises.length - 1,
                                        onComplete: _handleComplete,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: navbarSpace + bottomPad),
                          ],
                        ))
                : _buildPreStartPreview(lang, theme),
          ),

          if (!widget.isRecording)
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 120),
              child: GestureDetector(
                onTap: widget.onStart,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.textColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      lang.translate('map.startSession'),
                      style: TextStyle(
                        color: theme.boxColor,
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

  // ✅ PREVIEW LIST (READ-ONLY) — User lihat daftar gerakan, tidak bisa pilih/skip
  Widget _buildPreStartPreview(LanguageProvider lang, ThemeProvider theme) {
    return Column(
      children: [
        Text(
          lang.translate('map.targetToday'),
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: widget.exercises.length,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemBuilder: (context, i) {
              final ex = widget.exercises[i];
              final bool isInfo = ex['type'] == 'info';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.textColor.withOpacity(isInfo ? 0.03 : 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: theme.textColor.withOpacity(isInfo ? 0.05 : 0.08),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isInfo
                          ? Colors.amber.withOpacity(0.15)
                          : const Color(0xFF008BFF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isInfo
                          ? Icon(Icons.lightbulb, color: Colors.amber, size: 18)
                          : Text(
                              "${i + 1}",
                              style: TextStyle(
                                color: const Color(0xFF008BFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    ex['name'],
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    isInfo
                        ? ex['target']
                        : "${lang.translate('map.target')}: ${ex['target']}",
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.54),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ForwardBlockingScrollPhysics extends ScrollPhysics {
  const _ForwardBlockingScrollPhysics({super.parent});

  @override
  _ForwardBlockingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForwardBlockingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 🛑 Block Move to Next (Swipe Left / Negative Offset)
    if (offset < 0.0) return 0.0;

    // ✅ Allow Move to Prev (Swipe Right / Positive Offset)
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
