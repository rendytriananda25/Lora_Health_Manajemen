import 'package:flutter/material.dart';

/// Entity makanan — representasi satu item makanan untuk dashboard.
class FoodEntity {
  final String rawName;     // Nama asli (untuk translasi)
  final String displayName; // Nama yang ditampilkan
  final int rating;         // 5 = good, 2 = bad
  final String description; // "200 kcal • Tinggi protein"
  final IconData icon;
  final String type;        // 'good' atau 'bad'
  final String? mealTime;   // SARAPAN, MAKAN SIANG, MAKAN MALAM

  const FoodEntity({
    required this.rawName,
    required this.displayName,
    required this.rating,
    required this.description,
    required this.icon,
    required this.type,
    this.mealTime,
  });
}
