import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StatsRemoteDataSource {
  Future<List<String>> fetchUserSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseDatabase.instance
        .ref('users/${user.uid}/sports')
        .get();

    List<String> sports = [];
    if (snapshot.exists) {
      if (snapshot.value is Map) {
        (snapshot.value as Map).forEach((key, value) {
          if (value == true) {
            String s = key.toString().toUpperCase();
            if (s.contains('BMI')) s = 'CEK BMI';
            if (s.contains('HOME')) s = 'HOME WORKOUT';
            sports.add(s);
          }
        });
      } else if (snapshot.value is List) {
        for (var item in (snapshot.value as List)) {
          if (item != null) {
            String s = item.toString().toUpperCase();
            if (s.contains('BMI')) s = 'CEK BMI';
            if (s.contains('HOME')) s = 'HOME WORKOUT';
            sports.add(s);
          }
        }
      }
    }
    return sports;
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseDatabase.instance
        .ref('users/${user.uid}/history')
        .get();

    List<Map<String, dynamic>> history = [];
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        try {
          final entry = Map<String, dynamic>.from(value as Map);
          if (entry['time'] != null) {
            entry['date_obj'] = DateTime.parse(entry['time']);

            if (entry['activity'] != null) {
              String actString = entry['activity'].toString().toUpperCase();
              if (actString.contains('HOME')) actString = 'HOME WORKOUT';
              if (actString.contains('BMI')) actString = 'CEK BMI';
              entry['activity'] = actString;
            }
            history.add(entry);
          }
        } catch (e) {
          debugPrint('Skip data rusak: $e');
        }
      });
      history.sort((a, b) => a['date_obj'].compareTo(b['date_obj']));
    }
    return history;
  }
}
