import 'package:flutter/material.dart';

class BadgeItem {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const BadgeItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class BadgeList {
  static const List<BadgeItem> allBadges = [
    BadgeItem(
      id: 'first_step',
      icon: Icons.directions_run_rounded,
      color: Colors.blueAccent,
      title: "Langkah Pertama",
      description: "Selesaikan latihan pertamamu.",
    ),
    BadgeItem(
      id: 'streak_3',
      icon: Icons.local_fire_department_rounded,
      color: Colors.orangeAccent,
      title: "On Fire!",
      description: "Latihan 3 hari berturut-turut.",
    ),
    BadgeItem(
      id: 'session_10',
      icon: Icons.fitness_center_rounded,
      color: Colors.purpleAccent,
      title: "Dedikasi",
      description: "Selesaikan total 10 sesi latihan.",
    ),
    BadgeItem(
      id: 'dist_10k',
      icon: Icons.map_rounded,
      color: Colors.greenAccent,
      title: "Pelari 10K",
      description: "Capai total jarak 10 KM.",
    ),
    BadgeItem(
      id: 'cals_1000',
      icon: Icons.bakery_dining_rounded, // Burn calories
      color: Colors.redAccent,
      title: "Calorie Burner",
      description: "Bakar total 1000 kalori.",
    ),
    BadgeItem(
      id: 'time_morning',
      icon: Icons.wb_twilight_rounded,
      color: Colors.amber,
      title: "Early Bird",
      description: "Latihan di pagi hari (04:00 - 08:00).",
    ),
    BadgeItem(
      id: 'time_night',
      icon: Icons.nights_stay_rounded,
      color: Colors.indigoAccent,
      title: "Night Owl",
      description: "Latihan di malam hari (20:00 - 00:00).",
    ),
    BadgeItem(
      id: 'dist_42k',
      icon: Icons.emoji_events_rounded,
      color: Colors.amberAccent,
      title: "Marathoner",
      description: "Capai total jarak 42 KM (Marathon).",
    ),
  ];
}
