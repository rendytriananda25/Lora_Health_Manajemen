import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// App Colors — Palet warna sentral untuk seluruh aplikasi.
/// Menghindari hardcode warna di dalam widget.
/// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── PRIMARY ───────────────────────────────────────────────
  static const Color primary = Color(0xFF008BFF);
  static const Color primaryGlow = Color(0x66008BFF); // Shadow / glow

  // ─── DARK MODE ─────────────────────────────────────────────
  static const Color darkBg = Colors.black;
  static const Color darkBox = Color(0xFF141416);
  static const Color darkText = Colors.white;
  static const Color darkSubText = Colors.white54;
  static const Color darkBorder = Colors.white10;

  // ─── LIGHT MODE ────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightBox = Colors.white;
  static const Color lightText = Colors.black;
  static const Color lightSubText = Colors.black54;
  static const Color lightBorder = Colors.black12;

  // ─── STATUS / SEMANTIC ─────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ─── CARD ACCENT COLORS (Riwayat / Stats) ──────────────────
  static const Color cardPurple = Color(0xFFC7B8F5);
  static const Color cardCyan = Color(0xFFB2EBF2);
  static const Color cardGreen = Color(0xFFA5D6A7);
  static const Color cardBlue = Color(0xFF90CAF9);
}
