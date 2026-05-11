import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lora_1/features/notification/workout_reminder_service.dart';
import '../../screen/navbar.dart';
import '../data/setup_constants.dart';

class SetupService {
  static Future<void> saveAndStart(
    BuildContext context, {
    required Set<int> selectedIndices,
    required String level,
    required String goal,
    required String gender,
    required int height,
    required int weight,
    required int age,
    required int frequency,
    required int targetWeight,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();


      await prefs.setString('user_fitness_level', level);
      await prefs.setString('user_fitness_goal', goal);
      await prefs.setString('user_gender', gender);
      await prefs.setInt('user_height_cm', height);
      await prefs.setInt('user_weight_kg', weight);
      await prefs.setInt('user_age', age);
      await prefs.setInt('user_target_weight_kg', targetWeight);
      await prefs.setInt('user_frequency', frequency);

      if (user != null) {
        final selectedNames = selectedIndices
            .map((i) => SetupConstants.sports[i]['name'] ?? "Unknown")
            .toList();

        final Map<String, bool> sportsForMap = {};
        for (final name in selectedNames) {
          var key = name.toUpperCase();
          if (key == "RUNNING") key = "LARI";
          if (key == "CYCLING") key = "SEPEDA";
          if (key == "FOOTBALL") key = "BOLA";
          if (key == "BASKETBALL") key = "BASKET";
          sportsForMap[key] = true;
        }

        final genderLabel = gender == "MALE" ? "Laki-laki" : "Perempuan";

        await FirebaseDatabase.instance.ref("users/${user.uid}").update({
          "sports": sportsForMap,
          "favorite_sports": selectedNames,
          "fitness_level": level,
          "fitness_goal": goal,
          "onboarding_completed": true,
          "health_data": {
            "height": height,
            "weight": weight,
            "gender": genderLabel,
            "age": age,
            "target_weight": targetWeight,
            "frequency": frequency,
          },
        });

        await WorkoutReminderService.instance.scheduleDailyWellnessProgram(
          goal: goal,
          prioritySports: selectedNames,
        );

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Navbar()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error Saving Setup: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan data: $e")));
      }
    }
  }
}
