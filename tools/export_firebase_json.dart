// ignore_for_file: avoid_print
/// Tool: Export Nutrition & Workout data ke JSON
/// Jalankan: flutter test tools/export_firebase_json.dart
///
/// File JSON akan dibuat di folder tools/
/// Lalu import ke Firebase Console → Realtime Database → ⋮ → Import JSON

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lora_1/features/dashboard/data/nutrition_data.dart';
import 'package:lora_1/features/map/data/workout_data.dart';

void main() {
  test('Export nutrition & workout data to JSON files', () {
    final encoder = const JsonEncoder.withIndent('  ');

    // ─── Export Nutrition Data ───
    final nutritionJson = encoder.convert(NutritionData.foodRecommendations);
    File('tools/nutrition_data.json').writeAsStringSync(nutritionJson);
    print('✅ tools/nutrition_data.json exported!');

    // ─── Export Workout Library ───
    // Remove non-serializable fields (IconData) - Firebase only needs raw data
    final workoutRaw = _deepCleanMap(WorkoutData.defaultWorkoutLibrary);
    final workoutJson = encoder.convert(workoutRaw);
    File('tools/workout_data.json').writeAsStringSync(workoutJson);
    print('✅ tools/workout_data.json exported!');

    // ─── Export Progression Data ───
    final progressionJson = encoder.convert(WorkoutData.progressionData);
    File('tools/progression_data.json').writeAsStringSync(progressionJson);
    print('✅ tools/progression_data.json exported!');

    print('\n📁 3 file JSON siap di folder tools/');
    print('📌 Import ke Firebase Console:');
    print('   1. Buka https://console.firebase.google.com');
    print('   2. Realtime Database → ⋮ → Import JSON');
    print('   3. Pilih file yang ingin diupdate');
    print('   - nutrition_data.json → path: data/nutrition_data');
    print('   - workout_data.json  → path: data/workout_data');
  });
}

/// Recursively clean map - remove non-JSON-serializable values
dynamic _deepCleanMap(dynamic value) {
  if (value is Map) {
    final cleaned = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      // Skip IconData and other non-serializable objects
      if (val != null && val.runtimeType.toString().contains('IconData')) {
        continue;
      }
      cleaned[key] = _deepCleanMap(val);
    }
    return cleaned;
  } else if (value is List) {
    return value.map((e) => _deepCleanMap(e)).toList();
  }
  return value;
}
