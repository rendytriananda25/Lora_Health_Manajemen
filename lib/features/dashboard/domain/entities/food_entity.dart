import 'package:flutter/material.dart';

class FoodEntity {
  final String rawName;
  final String displayName;
  final int rating;
  final String description;
  final IconData icon;
  final String type;
  final String? mealTime;

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
