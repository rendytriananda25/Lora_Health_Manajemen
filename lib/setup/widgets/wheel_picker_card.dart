import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class WheelPickerCard extends StatefulWidget {
  final String title;
  final int min;
  final int max;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const WheelPickerCard({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<WheelPickerCard> createState() => _WheelPickerCardState();
}

class _WheelPickerCardState extends State<WheelPickerCard> {
  late FixedExtentScrollController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime _lastSoundAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.initialValue - widget.min,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playClick() async {
    final now = DateTime.now();
    if (now.difference(_lastSoundAt) < const Duration(milliseconds: 80)) return;
    _lastSoundAt = now;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/click.wav'), volume: 0.3);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.7),
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
                      horizontal: BorderSide(
                        color: theme.textColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 34,
                  perspective: 0.005,
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  onSelectedItemChanged: (index) {
                    widget.onChanged(widget.min + index);
                    _playClick();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.max - widget.min + 1,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${widget.min + index}',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 20,
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
}
