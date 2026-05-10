import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:lora_1/core/constants/api_constants.dart';
import 'package:lora_1/core/errors/exceptions.dart';

/// DataSource untuk data workout dari Firebase + API.
class WorkoutRemoteDataSource {
  /// Ambil daftar olahraga user dari Firebase.
  Future<List<String>> fetchUserSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const ServerException('User belum login');

    final snapshot = await FirebaseDatabase.instance
        .ref('users/${user.uid}/sports')
        .get();

    if (!snapshot.exists || snapshot.value is! Map) return [];

    List<String> loaded = [];
    (snapshot.value as Map).forEach((k, v) {
      if (v == true) {
        String text = k.toString();
        loaded.add(text.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' '));
      }
    });
    return loaded;
  }

  /// Ambil preferensi user dari Firebase + SharedPreferences.
  Future<Map<String, dynamic>> fetchUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String gender = 'UNKNOWN';
    int frequency = 1;
    double weight = 60.0;
    int totalSessions = 0;

    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}/health_data')
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        gender = data['gender']?.toString() ?? 'UNKNOWN';
        if (data['frequency'] != null) {
          frequency = int.tryParse(data['frequency'].toString()) ?? 1;
        }
        if (data['weight'] != null) {
          weight = double.tryParse(data['weight'].toString()) ?? 60.0;
        }
      }

      final gameSnap = await FirebaseDatabase.instance
          .ref('users/${user.uid}/gamification/total_sessions')
          .get();
      if (gameSnap.exists) {
        totalSessions = int.tryParse(gameSnap.value.toString()) ?? 0;
      }
    }

    return {
      'level': prefs.getString('user_fitness_level') ?? 'NEVER',
      'goal': prefs.getString('user_fitness_goal') ?? 'KEEP_FIT',
      'gender': gender,
      'frequency': frequency,
      'weight': weight > 0 ? weight : 60.0,
      'totalSessions': totalSessions,
    };
  }

  /// Ambil nama user dari Firebase.
  Future<String> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    final snapshot = await FirebaseDatabase.instance
        .ref('users/${user.uid}/username')
        .get();
    if (snapshot.exists) return snapshot.value.toString();
    return user.displayName ?? 'User';
  }

  /// Simpan sesi workout ke Firebase.
  Future<void> saveWorkoutSession(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const ServerException('User belum login');

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/history');
    await dbRef.push().set(data);
  }

  /// Ambil data cuaca berdasarkan koordinat.
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url = ApiConstants.weatherUrl(lat, lon, lang: 'id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw ServerException('Weather API error: ${response.statusCode}');
    }
    return json.decode(response.body);
  }
}
