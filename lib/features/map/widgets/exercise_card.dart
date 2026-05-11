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
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isTimerRunning = false;

  int _repsCount = 0;
  int _targetReps = 0;

  bool _isCompleted = false;

  YoutubePlayerController? _videoController;

  Timer? _videoInitTimer;

  @override
  void initState() {
    super.initState();
    _parseTarget();
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (!widget.isActive) {
        _disposeVideoPlayer();
      }
    }
  }

  void _parseTarget() {
    String t = widget.data['target'].toString().toLowerCase();

    if (t.contains("menit") || t.contains("min")) {
      final match = RegExp(r'(\d+)\s*(?:menit|min)').firstMatch(t);
      if (match != null) {
        _secondsLeft = int.parse(match.group(1)!) * 60;
      }
    } else if (t.contains("detik") || t.contains("sec")) {
      final match = RegExp(r'(\d+)\s*(?:detik|sec)').firstMatch(t);
      if (match != null) {
        _secondsLeft = int.parse(match.group(1)!);
      }
    }

    if (t.contains("reps") || t.contains("x")) {
      final match = RegExp(r'(\d+)').firstMatch(t);
      if (match != null) {
        _targetReps = int.parse(match.group(1)!);
        _repsCount = _targetReps;
      }
    }
  }

  bool get _hasVideoUrl =>
      widget.data['video_url'] != null &&
      widget.data['video_url'].toString().isNotEmpty;

  String get _thumbnailUrl {
    if (!_hasVideoUrl) return '';
    final videoId = YoutubePlayer.convertUrlToId(widget.data['video_url']) ?? '';
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  void _loadVideoOnDemand() {
    if (_videoController != null) return;

    if (widget.data['video_url'] != null &&
        widget.data['video_url'].toString().isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.data['video_url']);
      if (videoId != null) {
        int startSeconds = 0;
        if (widget.data['start_at'] != null) {
          startSeconds = int.tryParse(widget.data['start_at'].toString()) ?? 0;
        }

        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: true,
            startAt: startSeconds,
            disableDragSeek: true,
            loop: false,
            forceHD: false,
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
    _disposeVideoPlayer(notify: false);
    super.dispose();
  }

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

    String result = isTimer
        ? "Done ($_secondsLeft s left)"
        : "${widget.data['target']} selesai";

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
    final theme = Provider.of<ThemeProvider>(context);

    final cardColor = theme.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    final textColor = theme.isDarkMode ? Colors.white : Colors.black;
    final subTextColor = theme.isDarkMode ? Colors.white54 : Colors.black54;

    final buttonColor = theme.isDarkMode ? Colors.white : Colors.black;
    final buttonTextColor = theme.isDarkMode ? Colors.black : Colors.white;

    final iconCircleColor = theme.isDarkMode
        ? const Color(0xFF141416)
        : Colors.white;
    final iconColor = theme.isDarkMode ? Colors.white : Colors.black;

    String type = widget.data['type'] ?? "info";

    return LayoutBuilder(
      builder: (context, constraints) {

        final screenH = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final isCompact = screenH < 700;
        final isVeryCompact = screenH < 600;

        final titleSize = isVeryCompact ? 17.0 : isCompact ? 20.0 : 26.0;
        final subtitleSize = isVeryCompact ? 11.0 : isCompact ? 13.0 : 16.0;
        final contentPadTop = isVeryCompact ? 6.0 : isCompact ? 10.0 : 20.0;
        final buttonPadBottom = isVeryCompact ? 4.0 : isCompact ? 8.0 : 16.0;

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
                if (_hasVideoUrl)
                  Expanded(
                    flex: isCompact ? 2 : 3,
                    child: Container(
                      color: Colors.black,
                      child: _videoController != null
                          ? Stack(
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
                            )
                          : GestureDetector(
                              onTap: () => _loadVideoOnDemand(),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    _thumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black87,
                                      child: const Center(
                                        child: Icon(Icons.videocam_off, color: Colors.white38, size: 40),
                                      ),
                                    ),
                                  ),
                                  Container(color: Colors.black38),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF008BFF).withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                                  ),
                                  const Positioned(
                                    bottom: 10,
                                    child: Text(
                                      'Tap untuk putar tutorial',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                Expanded(
                  flex: isCompact ? 5 : 5,
                  child: LayoutBuilder(
                    builder: (context, infoConstraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: infoConstraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(25, contentPadTop, 25, buttonPadBottom),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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

                                    SizedBox(height: isCompact ? 3 : 5),

                                    if (type != 'reps')
                                      Text(
                                        widget.data['target'] ?? "Target",
                                        style: TextStyle(color: subTextColor, fontSize: subtitleSize),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 10),

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

                                const SizedBox(height: 10),

                                if (!_isCompleted)
                                  SwipeButton(
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
                                  )
                                else
                                  const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

class _SwipeButtonState extends State<SwipeButton>
    with TickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isDragging = false;
  bool _triggered = false;
  final double _padding = 6.0;
  final double _knobSize = 48.0;

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springController.addListener(() {
      if (mounted) setState(() => _dragValue = _springAnimation.value);
    });

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _successScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _springBack() {
    _springAnimation = Tween<double>(begin: _dragValue, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springController.forward(from: 0.0);
  }

  void _triggerSuccess() {
    setState(() => _triggered = true);
    _successController.forward(from: 0.0).then((_) {
      widget.onAction();
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _dragValue = 0.0;
              _isDragging = false;
              _triggered = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double maxDrag = maxWidth - _knobSize - (_padding * 2);
          final double knobLeft = _padding + (_dragValue * maxDrag);

          return AnimatedBuilder(
            animation: _successScale,
            builder: (context, child) => Transform.scale(
              scale: _triggered ? _successScale.value : 1.0,
              child: child,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  width: knobLeft + _knobSize / 2,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        widget.iconCircleColor.withOpacity(0.15),
                        widget.iconCircleColor.withOpacity(
                          0.05 + (_dragValue * 0.25),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: _knobSize + 10,
                        right: _knobSize / 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Opacity(
                              opacity: (1.0 - _dragValue * 1.5).clamp(0.0, 1.0),
                              child: Text(
                                widget.text,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 2.0,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (!_isDragging && _dragValue == 0.0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (i) => Opacity(
                                opacity: 0.3 + (i * 0.15),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: widget.textColor,
                                  size: 16,
                                ),
                              )),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: knobLeft,
                  top: _padding,
                  bottom: _padding,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      _springController.stop();
                      setState(() => _isDragging = true);
                    },
                    onHorizontalDragUpdate: (details) {
                      double delta = details.primaryDelta! / maxDrag;
                      setState(() {
                        _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (_dragValue > 0.6) {
                        setState(() {
                          _dragValue = 1.0;
                          _isDragging = false;
                        });
                        _triggerSuccess();
                      } else {
                        setState(() => _isDragging = false);
                        _springBack();
                      }
                    },
                    onTap: () => widget.onAction(),
                    child: Transform.scale(
                      scale: _isDragging ? 1.08 : 1.0,
                      child: Container(
                        width: _knobSize,
                        height: _knobSize,
                        decoration: BoxDecoration(
                          color: _triggered
                              ? Colors.green
                              : widget.iconCircleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (!_isDragging)
                              BoxShadow(
                                color: (_triggered
                                        ? Colors.green
                                        : widget.iconCircleColor)
                                    .withOpacity(0.15),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _triggered ? Icons.check : widget.icon,
                            key: ValueKey(_triggered),
                            color: _triggered
                                ? Colors.white
                                : widget.iconColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
