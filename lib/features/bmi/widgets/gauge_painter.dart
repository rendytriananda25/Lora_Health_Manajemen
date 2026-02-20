import 'dart:math';
import 'package:flutter/material.dart';

class GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color bgColor;

  GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = size.width * 0.45;

    // Background Arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Needle Logic (Jarum)
    final progress = (value.clamp(min, max) - min) / (max - min);
    final needleAngle = pi + (progress * pi);
    final needleEnd = Offset(
      center.dx + (radius - 10) * cos(needleAngle),
      center.dy + (radius - 10) * sin(needleAngle),
    );

    // Draw Jarum
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = const Color(0xFF008BFF)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
