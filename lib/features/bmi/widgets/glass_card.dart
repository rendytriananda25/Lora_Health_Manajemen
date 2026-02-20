import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: theme.boxColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
