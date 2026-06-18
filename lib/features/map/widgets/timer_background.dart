import 'package:flutter/material.dart';
import 'package:lora_1/features/map/widgets/exercise_card.dart';
import 'package:lora_1/features/map/services/session_completion_service.dart';
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
  final bool sessionCompleted;

  const TimerBackground({
    super.key,
    required this.selectedSport,
    required this.isRecording,
    required this.secondsNotifier,
    required this.exercises,
    required this.onStop,
    required this.onStart,
    required this.onCompleteExercise,
    this.sessionCompleted = false,
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

  void _handleComplete(String name, String result) {
    widget.onCompleteExercise(name, result);

    if (_currentExerciseIndex < widget.exercises.length - 1) {
      _pageController.animateToPage(
        _currentExerciseIndex + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final navbarSpace = (screenHeight * 0.14).clamp(90.0, 130.0);
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
                : widget.sessionCompleted
                    ? _buildSessionDoneMessage(lang, theme)
                    : _buildPreStartPreview(lang, theme),
          ),

          if (!widget.isRecording && !widget.sessionCompleted)
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

  Widget _buildSessionDoneMessage(LanguageProvider lang, ThemeProvider theme) {
    final timeLeft = SessionCompletionService.getTimeUntilNextSession();
    final timeStr = SessionCompletionService.formatDuration(timeLeft);
    final sessionLabel = SessionCompletionService.getCurrentSessionLabel();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E676).withOpacity(0.08),
                        const Color(0xFF00E676).withOpacity(0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      width: 2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00E676).withOpacity(0.12),
                        const Color(0xFF00C853).withOpacity(0.06),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00E676),
                    size: 36,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              "$sessionLabel Selesai",
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              "Latihan telah diselesaikan.\nTubuhmu butuh recovery untuk performa maksimal.",
              style: TextStyle(
                color: theme.textColor.withOpacity(0.5),
                fontSize: 13,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: theme.textColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color(0xFF008BFF).withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF008BFF).withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF008BFF),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Sesi berikutnya dalam ",
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF008BFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

    if (offset < 0.0) return 0.0;

    return super.applyPhysicsToUserOffset(position, offset);
  }
}
