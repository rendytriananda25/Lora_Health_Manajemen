import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  final bool isLastExercise;
  final Function(String name, String result) onComplete;

  const ExerciseCard({
    super.key,
    required this.data,
    required this.isActive,
    required this.isLastExercise,
    required this.onComplete,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  // Timer State
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isTimerRunning = false;

  // Reps State
  int _repsCount = 0;
  int _targetReps = 0;

  bool _isCompleted = false;

  // Video Player
  YoutubePlayerController? _videoController;

  // Init Timer (Video Delay)
  Timer? _videoInitTimer;

  @override
  void initState() {
    super.initState();
    _parseTarget();
    // OPTIMISASI PERFORMA: Delay load video
    if (widget.isActive) {
      _scheduleVideoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _scheduleVideoPlay();
      } else {
        _disposeVideoPlayer();
      }
    }
  }

  void _parseTarget() {
    String t = widget.data['target'].toString().toLowerCase();

    // Parse Waktu
    if (t.contains("menit") || t.contains("min")) {
      final match = RegExp(r'(\d+)').firstMatch(t);
      if (match != null) {
        _secondsLeft = int.parse(match.group(1)!) * 60;
      }
    } else if (t.contains("detik") || t.contains("sec")) {
      final match = RegExp(r'(\d+)').firstMatch(t);
      if (match != null) {
        _secondsLeft = int.parse(match.group(1)!);
      }
    }

    // Parse Reps
    if (t.contains("reps") || t.contains("x")) {
      final match = RegExp(r'(\d+)').firstMatch(t);
      if (match != null) {
        _targetReps = int.parse(match.group(1)!);
        // Default repsCount = 0 or targetReps?
        // Usually start from 0 and count up, or from target and count down.
        // Based on screenshot "12 Repetisi" and "12" in center, let's assume we modify the count.
        // For now, init at target if the user wants countdown or 0 for countup.
        // Screenshot shows "12" large, and "12 Reps" small above.
        // Let's set initial _repsCount to _targetReps so user can adjust if needed,
        // OR simply set it to _targetReps as the goal.
        // To match typical workout apps: Center number is what you did or target.
        // Let's use _repsCount to track progress.
        _repsCount = _targetReps;
      }
    }
  }

  void _scheduleVideoPlay() {
    _videoInitTimer?.cancel();
    // Delay 800ms to let UI finish transitions/animations first
    _videoInitTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && widget.isActive) {
        _initVideoPlayer();
      }
    });
  }

  void _initVideoPlayer() {
    if (_videoController != null) return;

    if (widget.data['video_url'] != null &&
        widget.data['video_url'].toString().isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.data['video_url']);
      if (videoId != null) {
        int startSeconds = 0;
        if (widget.data['start_at'] != null) {
          startSeconds = int.tryParse(widget.data['start_at'].toString()) ?? 0;
        }

        // Initialize Controller
        // Note: YoutubePlayerController can trigger platform channel work.
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            startAt: startSeconds,
            disableDragSeek: true,
            loop: true,
            forceHD: false, // Low end device preference
            hideControls: false,
          ),
        );

        if (mounted) setState(() {});
      }
    }
  }

  void _disposeVideoPlayer({bool notify = true}) {
    _videoInitTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposeVideoPlayer(notify: false); // Jangan setState saat dispose!
    super.dispose();
  }

  // --- LOGIKA TIMER ---
  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_secondsLeft > 0) {
              _secondsLeft--;
            } else {
              _handleFinish(isTimer: true);
            }
          });
        }
      });
    }
  }

  void _modifyReps(int delta) {
    setState(() {
      _repsCount += delta;
      if (_repsCount < 0) _repsCount = 0;
    });
  }

  void _handleFinish({required bool isTimer}) {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isCompleted = true;
    });

    // Panggil callback parent
    String result = isTimer
        ? "Done ($_secondsLeft s left)"
        : "$_repsCount Reps";

    // ✅ FIX: Kasih delay 1.5 detik agar user sempat lihat "Centang Hijau" sebelum pindah/tutup
    if (isTimer) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.onComplete(widget.data['name'], result);
        }
      });
    } else {
      widget.onComplete(widget.data['name'], result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context); // Get user theme

    // Integrated Theme Colors
    // DARK MODE: Color(0xFF1C1C1E) (Dark Grey)
    // LIGHT MODE: Colors.white (Clean White)
    final cardColor = theme.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    // DARK MODE: Text White
    // LIGHT MODE: Text Black
    final textColor = theme.isDarkMode ? Colors.white : Colors.black;
    final subTextColor = theme.isDarkMode ? Colors.white54 : Colors.black54;

    // Button Logic
    // DARK MODE: Button White, Text Black (as per Modern Dark design)
    // LIGHT MODE: Button Black, Text White (Classy contrast)
    final buttonColor = theme.isDarkMode ? Colors.white : Colors.black;
    final buttonTextColor = theme.isDarkMode ? Colors.black : Colors.white;

    // Icon Arrow
    // Dark Mode: White button -> Black Circle -> White Arrow inside?
    // Wait, preivous was DarkCircle on White Button.
    // Light Mode: Black button -> White Circle?
    final iconCircleColor = theme.isDarkMode
        ? const Color(0xFF141416)
        : Colors.white;
    final iconColor = theme.isDarkMode ? Colors.white : Colors.black;

    String type = widget.data['type'] ?? "info";

    return Container(
      width: double.infinity,
      // Reduced vertical margin to fix overflow
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
        border: Border.all(
          color: widget.isActive
              ? (theme.isDarkMode ? Colors.white10 : Colors.black12)
              : Colors.transparent,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // 1. VIDEO AREA
            // Show ONLY if video controller is initialized (i.e., valid video exists)
            if (_videoController != null)
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors
                      .black, // Video area always dark/black background even in light mode
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      YoutubePlayer(
                        controller: _videoController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: const Color(0xFF008BFF),
                        progressColors: const ProgressBarColors(
                          playedColor: Color(0xFF008BFF),
                          handleColor: Colors.white,
                        ),
                      ),
                      if (_isCompleted)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 60,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // 2. INFO AREA
            Expanded(
              flex: 4, // More space for controls to prevent overflow
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 30, 25, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Area (No Sun Icon)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sun Icon REMOVED
                            Expanded(
                              child: Text(
                                widget.data['name'],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            // External Link
                            if (widget.data['video_url'] != null &&
                                widget.data['video_url'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  Icons.open_in_new,
                                  color: theme.isDarkMode
                                      ? Colors.white30
                                      : Colors.black38,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),

                        // Spacer to push explanation to middle if no video
                        if (_videoController == null) const Spacer(),

                        const SizedBox(height: 5),

                        // Subtitle / Explanation
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 0, // Reset left padding since no icon above
                          ),
                          child: Text(
                            widget.data['target'] ?? "Target",
                            style: TextStyle(color: subTextColor, fontSize: 16),
                          ),
                        ),

                        if (_videoController == null) const Spacer(),

                        const Spacer(),

                        // Center Control (Timer or Reps)
                        Center(
                          child: type == 'time'
                              ? _buildTimerDisplay(
                                  textColor,
                                  subTextColor,
                                  lang,
                                )
                              : (type == 'reps'
                                    ? _buildRepsControl(
                                        textColor,
                                        subTextColor,
                                        lang,
                                      )
                                    : const SizedBox()),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),

                  // Bottom Button (Swipe to Action)
                  if (!_isCompleted)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 25,
                          left: 25,
                          right: 25,
                        ),
                        child: SwipeButton(
                          text: type == 'time'
                              ? (_isTimerRunning ? "PAUSE" : "MULAI TIMER")
                              : "LANJUT",
                          textColor: buttonTextColor,
                          backgroundColor: buttonColor,
                          iconCircleColor: iconCircleColor,
                          iconColor: iconColor,
                          icon: type == 'time' && _isTimerRunning
                              ? Icons.pause
                              : Icons.double_arrow_rounded,
                          onAction: () async {
                            if (type == 'time') {
                              _toggleTimer();
                            } else {
                              widget.onComplete(widget.data['name'], "Done");
                            }
                          },
                        ),
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

  // Helper widget for Icon
  Widget errorAwareIcon(IconData icon, Color color) {
    return Icon(icon, color: color, size: 20);
  }

  Widget _buildTimerDisplay(
    Color textColor,
    Color subColor,
    LanguageProvider lang,
  ) {
    int m = _secondsLeft ~/ 60;
    int s = _secondsLeft % 60;
    return Text(
      "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}",
      style: TextStyle(
        color: textColor,
        fontSize: 56,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildRepsControl(
    Color textColor,
    Color subColor,
    LanguageProvider lang,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MINUS BUTTON
            IconButton(
              onPressed: () => _modifyReps(-1),
              icon: const Icon(
                Icons.remove,
                color: Color(0xFF008BFF),
                size: 32,
              ),
            ),

            const SizedBox(width: 20),

            // NUMBER
            Text(
              "$_repsCount",
              style: TextStyle(
                color: textColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 20),

            // PLUS BUTTON
            IconButton(
              onPressed: () => _modifyReps(1),
              icon: const Icon(Icons.add, color: Color(0xFF008BFF), size: 32),
            ),
          ],
        ),
        Text("Repetisi", style: TextStyle(color: subColor, fontSize: 14)),
      ],
    );
  }
}

// ----------------------------------------------------
// 🔥 CUSTOM SWIPE BUTTON (SLIDER) 🔥
// ----------------------------------------------------
class SwipeButton extends StatefulWidget {
  final String text;
  final VoidCallback onAction;
  final Color textColor;
  final Color backgroundColor;
  final Color iconCircleColor;
  final Color iconColor;
  final IconData icon;

  const SwipeButton({
    super.key,
    required this.text,
    required this.onAction,
    required this.textColor,
    required this.backgroundColor,
    required this.iconCircleColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _dragValue = 0.0;
  bool _isDragging = false;
  final double _padding = 6.0;
  final double _knobSize = 48.0; // 60 height - padding*2

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double maxDrag = maxWidth - _knobSize - (_padding * 2);

          return Stack(
            children: [
              // 1. Background Container
              Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: _knobSize + 10,
                      right: _knobSize / 2,
                    ),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // 2. Sliding Knob
              Positioned(
                left: _padding + (_dragValue * maxDrag),
                top: _padding,
                bottom: _padding,
                child: GestureDetector(
                  onHorizontalDragStart: (details) {
                    setState(() => _isDragging = true);
                  },
                  onHorizontalDragUpdate: (details) {
                    double delta = details.primaryDelta! / maxDrag;
                    setState(() {
                      _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragValue > 0.6) {
                      // Trigger Action
                      widget.onAction();
                      // Reset with delay for visual feedback? Or instant?
                      // Usually immediate reset or stay if loading.
                      // For now reset.
                      setState(() {
                        _dragValue = 0.0;
                        _isDragging = false;
                      });
                    } else {
                      // Reset spring back
                      setState(() {
                        _dragValue = 0.0;
                        _isDragging = false;
                      });
                    }
                  },
                  onTap: () {
                    // Also support TAP for accessibility/ease
                    widget.onAction();
                  },
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      color: widget.iconCircleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
