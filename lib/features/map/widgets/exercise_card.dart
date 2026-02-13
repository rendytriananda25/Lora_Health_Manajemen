import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

class ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  final Function(String name, String result) onComplete;

  const ExerciseCard({
    super.key,
    required this.data,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  int _currentRepsInput = 10;

  @override
  void initState() {
    super.initState();
    // Parse target reps awal
    String clean = widget.data['target'].replaceAll(RegExp(r'[^0-9]'), '');
    _currentRepsInput = int.tryParse(clean) ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isActive ? const Color(0xFF1E1E1E) : Colors.black,
        borderRadius: BorderRadius.circular(30),
        border: widget.isActive
            ? Border.all(color: const Color(0xFF5EEAD4), width: 1.5)
            : Border.all(color: Colors.white10),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF5EEAD4).withOpacity(0.2),
                  blurRadius: 15,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isActive)
            const Align(
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white24,
                size: 20,
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
                image: widget.data['image'] != null
                    ? DecorationImage(
                        image: AssetImage(widget.data['image']),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: widget.data['image'] == null
                  ? Center(
                      child: Icon(
                        widget.data['icon'] ?? Icons.fitness_center,
                        size: 80,
                        color: Colors.white24,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.data['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            "${lang.translate('map.target')}: ${widget.data['target']}",
            style: const TextStyle(
              color: Color(0xFF5EEAD4),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          if (widget.isActive) ...[
            if (widget.data['type'] == 'reps')
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCounterButton(Icons.remove, () {
                        if (_currentRepsInput > 0)
                          setState(() => _currentRepsInput--);
                        HapticFeedback.selectionClick();
                      }),
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: Text(
                          "$_currentRepsInput",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCounterButton(Icons.add, () {
                        setState(() => _currentRepsInput++);
                        HapticFeedback.selectionClick();
                      }),
                    ],
                  ),
                  Text(
                    lang.translate('map.repetition'),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    lang.translate('map.done'),
                    () => widget.onComplete(
                      widget.data['name'],
                      "$_currentRepsInput Reps",
                    ),
                    isPrimary: true,
                    width: 200,
                  ),
                ],
              )
            else
              _buildActionButton(
                "${lang.translate('map.done')} (${widget.data['target']})",
                () => widget.onComplete(
                  widget.data['name'],
                  widget.data['target'],
                ),
                isPrimary: true,
                width: 200,
              ),

            const SizedBox(height: 10),
            Text(
              lang.translate('map.swipeToSkip'),
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else
            const Icon(Icons.lock_clock, color: Colors.white24, size: 30),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
    double width = 80,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF5EEAD4) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
