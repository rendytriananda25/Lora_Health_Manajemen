import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lora_1/core/errors/exceptions.dart';
import 'package:lora_1/features/gamification/badge_service.dart';

class UserRemoteDataSource {
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const ServerException('User belum login');

    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString('user_fitness_level') ?? 'NEVER';
    final goal = prefs.getString('user_fitness_goal') ?? 'KEEP_FIT';
    final savedPhoto = prefs.getString('user_local_photo');

    final profileSnap = await FirebaseDatabase.instance
        .ref('users/${user.uid}')
        .get();

    String resolvedName = user.displayName ?? 'User';
    if (profileSnap.exists && profileSnap.value is Map) {
      final data = Map<String, dynamic>.from(profileSnap.value as Map);
      resolvedName = data['username']?.toString()
          ?? data['full_name']?.toString()
          ?? resolvedName;
    }

    List<String> favorites = [];
    final sportsSnap = await FirebaseDatabase.instance
        .ref('users/${user.uid}/favorite_sports')
        .get();
    if (sportsSnap.exists && sportsSnap.value is List) {
      favorites = List<String>.from(sportsSnap.value as List);
    }

    return {
      'uid': user.uid,
      'name': resolvedName,
      'localPhotoPath': savedPhoto,
      'fitnessLevel': level,
      'fitnessGoal': goal,
      'favoriteSports': favorites,
    };
  }

  Stream<String> watchUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseDatabase.instance
        .ref('users/${user.uid}')
        .onValue
        .map((event) {
      if (event.snapshot.value is! Map) return user.displayName ?? 'User';
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data['username']?.toString()
          ?? data['full_name']?.toString()
          ?? user.displayName
          ?? 'User';
    });
  }

  Stream<int> watchUserExp() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseDatabase.instance
        .ref('users/${user.uid}/gamification/exp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return 0;
      return int.tryParse(event.snapshot.value.toString()) ?? 0;
    });
  }

  Future<int> checkDailyLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    return await BadgeService.checkDailyLogin(user.uid);
  }
}
