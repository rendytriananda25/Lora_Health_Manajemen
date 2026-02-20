import 'package:flutter/material.dart';

class HumanPainter extends CustomPainter {
  final Color color;
  final bool
  isFemale; // Optional: Nanti bisa ditambah logic kalau user mau cewek

  HumanPainter({required this.color, this.isFemale = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Head (Kepala)
    final headRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.12),
      width: w * 0.25,
      height: w * 0.25,
    );
    canvas.drawOval(headRect, paint);

    // Body (Badan) - Segitiga Terbalik
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.25)
      ..lineTo(w * 0.75, h * 0.25)
      ..lineTo(w * 0.70, h * 0.60)
      ..lineTo(w * 0.30, h * 0.60)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Legs (Kaki)
    final leftLeg = Path()
      ..moveTo(w * 0.32, h * 0.60)
      ..lineTo(w * 0.48, h * 0.60)
      ..lineTo(w * 0.48, h * 0.95)
      ..lineTo(w * 0.32, h * 0.95)
      ..close();
    canvas.drawPath(leftLeg, paint);

    final rightLeg = Path()
      ..moveTo(w * 0.52, h * 0.60)
      ..lineTo(w * 0.68, h * 0.60)
      ..lineTo(w * 0.68, h * 0.95)
      ..lineTo(w * 0.52, h * 0.95)
      ..close();
    canvas.drawPath(rightLeg, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
