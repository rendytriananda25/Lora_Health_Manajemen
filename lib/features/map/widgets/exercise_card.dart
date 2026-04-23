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


  void _handleFinish({required bool isTimer}) {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isCompleted = true;
    });

    // Panggil callback parent
    String result = isTimer
        ? "Done ($_secondsLeft s left)"
        : "${widget.data['target']} selesai";

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🔥 Responsive sizing berdasarkan screen height device (bukan card)
        final screenH = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final isCompact = screenH < 700; // Device kecil (< 700dp)
        final isVeryCompact = screenH < 600; // Device sangat kecil

        final titleSize = isVeryCompact ? 17.0 : isCompact ? 20.0 : 26.0;
        final subtitleSize = isVeryCompact ? 11.0 : isCompact ? 13.0 : 16.0;
        final contentPadTop = isVeryCompact ? 10.0 : isCompact ? 16.0 : 24.0;
        // Padding bawah konten: cukup untuk button (~70px) + safe area
        final contentPadBottom = (70.0 + bottomInset).clamp(70.0, 100.0);
        final buttonPadBottom = isVeryCompact ? 8.0 : isCompact ? 14.0 : 20.0;

        return Container(
          width: double.infinity,
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
                if (_videoController != null)
                  Expanded(
                    flex: isCompact ? 3 : 4,
                    child: Container(
                      color: Colors.black,
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
                  flex: isCompact ? 5 : 4,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(25, contentPadTop, 25, contentPadBottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Area
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.data['name'],
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w400,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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

                            if (_videoController == null) const Spacer(),

                            SizedBox(height: isCompact ? 3 : 5),

                            // Subtitle hanya tampil untuk timer/info, bukan reps (sudah tampil besar di bawah)
                            if (type != 'reps')
                              Text(
                                widget.data['target'] ?? "Target",
                                style: TextStyle(color: subTextColor, fontSize: subtitleSize),
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
                                      isCompact,
                                    )
                                  : (type == 'reps'
                                        ? _buildRepsDisplay(
                                            textColor,
                                            subTextColor,
                                            isCompact,
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
                            padding: EdgeInsets.only(
                              bottom: buttonPadBottom,
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
                                  _handleFinish(isTimer: false);
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
      },
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
    bool isCompact,
  ) {
    int m = _secondsLeft ~/ 60;
    int s = _secondsLeft % 60;
    return Text(
      "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}",
      style: TextStyle(
        color: textColor,
        fontSize: isCompact ? 40 : 56,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }

  // Tampilan statis target repetisi (tidak bisa diubah user)
  Widget _buildRepsDisplay(
    Color textColor,
    Color subColor,
    bool isCompact,
  ) {
    final targetLabel = widget.data['target']?.toString() ?? "$_targetReps Reps";
    return Text(
      targetLabel,
      style: TextStyle(
        color: textColor,
        fontSize: isCompact ? 32 : 44,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
