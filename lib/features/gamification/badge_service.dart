import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'badges.dart';
import 'rank_system.dart';

class BadgeService {
  static Future<GamificationResult> processSession(
    String userId,
    Map<String, dynamic> sessionData,
  ) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final userNode = dbRef.child("users/$userId");

    final gameSnap = await userNode.child("gamification").get();
    final badgeSnap = await userNode.child("badges").get();

    int currentExp = 0;
    int currentStreak = 0;
    String? lastDateStr;
    double totalDist = 0;
    int totalCals = 0;
    int totalSessions = 0;

    bool needsMigration = true;

    if (gameSnap.exists && gameSnap.value is Map) {
      final data = gameSnap.value as Map;
      currentExp = int.tryParse(data['exp'].toString()) ?? 0;
      currentStreak = int.tryParse(data['streak'].toString()) ?? 0;
      lastDateStr = data['last_workout_date']?.toString();

      if (data.containsKey('total_distance')) {
        needsMigration = false;
        totalDist = double.tryParse(data['total_distance'].toString()) ?? 0;
        totalCals = int.tryParse(data['total_calories'].toString()) ?? 0;
        totalSessions = int.tryParse(data['total_sessions'].toString()) ?? 0;
      }
    }
    if (needsMigration) {
      final historySnap = await userNode.child("history").get();
      if (historySnap.exists && historySnap.value is Map) {
        final hData = historySnap.value as Map;
        totalSessions = hData.length;
        hData.forEach((k, v) {
          final s = v as Map;
          totalDist += (s['distance_km'] as num? ?? 0).toDouble();
          totalCals += (s['calories'] as num? ?? 0).toInt();
        });
      }
    }

    if (!needsMigration) {
      totalDist += (sessionData['distance_km'] as num? ?? 0).toDouble();
      totalCals += (sessionData['calories'] as num? ?? 0).toInt();
      totalSessions += 1;
    }

    DateTime now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    int bonusExp = 0;
    bool isDailyBonus = false;
    bool isWeeklyBonus = false;

    if (lastDateStr != todayStr) {
      isDailyBonus = true;
      bonusExp += 100;

      bool continued = false;
      if (lastDateStr != null) {
        DateTime last = _parseDate(lastDateStr!);
        DateTime today = DateTime(now.year, now.month, now.day);
        if (today.difference(last).inDays == 1) continued = true;
      }

      if (continued) {
        currentStreak++;
        if (currentStreak % 7 == 0) {
          isWeeklyBonus = true;
          bonusExp += 200;
        }
      } else {
        currentStreak = 1;
      }
    }

    int baseExp = _calculateBaseExp(sessionData);
    int totalGained = baseExp + bonusExp;
    int newExp = currentExp + totalGained;

    RankData oldRank = RankSystem.getRank(currentExp);
    RankData newRankInfo = RankSystem.getRank(newExp);
    bool isRankUp = newRankInfo.id > oldRank.id;

    List<String> unlockedIds = [];
    if (badgeSnap.exists) {
      if (badgeSnap.value is List) {
        unlockedIds = List<String>.from(
          (badgeSnap.value as List).where((e) => e != null),
        );
      } else if (badgeSnap.value is Map) {
        unlockedIds = (badgeSnap.value as Map).values
            .map((e) => e.toString())
            .toList();
      }
    }

    List<BadgeItem> newBadges = [];
    DateTime sessionTime = DateTime.parse(
      sessionData['time'] ?? now.toIso8601String(),
    );

    for (var badge in BadgeList.allBadges) {
      if (unlockedIds.contains(badge.id)) continue;

      bool unlocked = false;
      switch (badge.id) {
        case 'first_step':
          if (totalSessions >= 1) unlocked = true;
          break;
        case 'session_10':
          if (totalSessions >= 10) unlocked = true;
          break;
        case 'dist_10k':
          if (totalDist >= 10) unlocked = true;
          break;
        case 'dist_42k':
          if (totalDist >= 42) unlocked = true;
          break;
        case 'cals_1000':
          if (totalCals >= 1000) unlocked = true;
          break;
        case 'time_morning':
          if (sessionTime.hour >= 4 && sessionTime.hour < 8) unlocked = true;
          break;
        case 'time_night':
          if (sessionTime.hour >= 20 || sessionTime.hour < 0) unlocked = true;
          break;
        case 'streak_3':
          if (currentStreak >= 3) unlocked = true;
          break;
      }

      if (unlocked) {
        newBadges.add(badge);
        unlockedIds.add(badge.id);
      }
    }

    Map<String, dynamic> updates = {
      "gamification/exp": newExp,
      "gamification/streak": currentStreak,
      "gamification/last_workout_date": todayStr,
      "gamification/total_distance": totalDist,
      "gamification/total_calories": totalCals,
      "gamification/total_sessions": totalSessions,
    };
    if (newBadges.isNotEmpty) {
      updates["badges"] = unlockedIds;
    }

    await userNode.update(updates);

    return GamificationResult(
      gainedExp: totalGained,
      newTotalExp: newExp,
      isRankUp: isRankUp,
      newRank: newRankInfo,
      newBadges: newBadges,
    );
  }

  static int _calculateBaseExp(Map<String, dynamic> sessionData) {
    if (sessionData['workout_details'] != null &&
        sessionData['workout_details'] is List) {
      List details = sessionData['workout_details'] as List;
      if (details.isEmpty) return 50;
      int count = details.length;
      int perItem = (125 / count).ceil();
      if (perItem < 10) perItem = 10;
      return count * perItem;
    } else {
      int cals = int.tryParse(sessionData['calories'].toString()) ?? 0;
      int distExp =
          ((double.tryParse(sessionData['distance_km'].toString()) ?? 0) * 10)
              .toInt();
      int total = 50 + (cals ~/ 4) + distExp;
      return total;
    }
  }

  static Future<int> checkDailyLogin(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref("users/$userId/gamification");

    try {
      final snapshot = await dbRef.child("last_login_date").get();

      DateTime now = DateTime.now();
      String todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      String? lastLoginStr = snapshot.exists ? snapshot.value.toString() : null;

      debugPrint("🔍 Daily Login Check: Last=$lastLoginStr, Today=$todayStr");

      if (lastLoginStr != todayStr) {
        final expSnap = await dbRef.child("exp").get();
        int currentExp = expSnap.exists
            ? (int.tryParse(expSnap.value.toString()) ?? 0)
            : 0;

        int bonusExp = 20;
        int newExp = currentExp + bonusExp;

        debugPrint("🚀 Granting Daily Login: +$bonusExp EXP. Total: $newExp");

        await dbRef.update({"exp": newExp, "last_login_date": todayStr});

        return bonusExp;
      } else {
        debugPrint("✅ Already claimed daily login today.");
      }

      return 0;
    } catch (e) {
      debugPrint("❌ Error in checkDailyLogin: $e");
      return 0;
    }
  }

  static DateTime _parseDate(String s) {
    List<String> p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static Future<List<String>> getUnlockedBadges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await FirebaseDatabase.instance
        .ref("users/${user.uid}/badges")
        .get();
    if (!snap.exists) return [];
    if (snap.value is List)
      return List<String>.from((snap.value as List).where((e) => e != null));
    return (snap.value as Map).values.map((e) => e.toString()).toList();
  }
}

class GamificationResult {
  final int gainedExp;
  final int newTotalExp;
  final bool isRankUp;
  final RankData newRank;
  final List<BadgeItem> newBadges;

  GamificationResult({
    required this.gainedExp,
    required this.newTotalExp,
    required this.isRankUp,
    required this.newRank,
    required this.newBadges,
  });
}
