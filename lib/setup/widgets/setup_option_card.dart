import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class SetupOptionCard extends StatelessWidget {
  final String label;
  final String? subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const SetupOptionCard({
    super.key,
    required this.label,
    this.subLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008BFF).withOpacity(0.15)
              : theme.boxColor, // Adaptive Box Color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF008BFF)
                : theme.textColor.withOpacity(0.1), // Adaptive Border
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF008BFF)
                  : theme.textColor.withOpacity(0.24),
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
                      color: isSelected
                          ? const Color(0xFF008BFF)
                          : theme.textColor, // Adaptive Text
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(
                          0.54,
                        ), // Adaptive Subtext
                        fontSize: 12,
                      ),
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
}
