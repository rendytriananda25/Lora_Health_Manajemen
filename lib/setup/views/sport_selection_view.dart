import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import '../../setup/data/setup_constants.dart';

class SportSelectionView extends StatefulWidget {
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;

  const SportSelectionView({
    super.key,
    required this.selectedIndices,
    required this.onToggle,
  });

  @override
  State<SportSelectionView> createState() => _SportSelectionViewState();
}

class _SportSelectionViewState extends State<SportSelectionView> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Olahraga",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pilih jenis olahraga yang kamu suka (Boleh lebih dari satu)",
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.54),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.bgColor,
                theme.bgColor,
                Colors.transparent,
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              itemCount: SetupConstants.sports.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemBuilder: (context, index) {
                final sport = SetupConstants.sports[index];
                final isSelected = widget.selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () => widget.onToggle(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: isSelected
                          ? const Color(0xFF008BFF).withOpacity(0.8)
                          : theme.boxColor,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF008BFF)
                            : theme.textColor.withOpacity(0.1),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF008BFF).withOpacity(0.3),
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
                              sport['img']!,
                              fit: BoxFit.cover,
                              alignment: Alignment.centerRight,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.broken_image,
                                color: theme.textColor.withOpacity(0.24),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withOpacity(
                                    0.8,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sport['name']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
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
      ],
    );
  }
}
