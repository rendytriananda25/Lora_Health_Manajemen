import 'package:flutter/material.dart';

/// Entity untuk data statistik yang sudah diproses.
class StatsSummaryEntity {
  final int totalSessions;
  final int totalCalories;
  final double totalDistance;
  final int totalDurationMin;
  final double maxDistanceRecord;
  final Map<String, int> maxRepsRecord;
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> bmiWeightData;

  const StatsSummaryEntity({
    required this.totalSessions,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalDurationMin,
    required this.maxDistanceRecord,
    required this.maxRepsRecord,
    required this.chartData,
    required this.bmiWeightData,
  });

  factory StatsSummaryEntity.empty() => const StatsSummaryEntity(
    totalSessions: 0,
    totalCalories: 0,
    totalDistance: 0.0,
    totalDurationMin: 0,
    maxDistanceRecord: 0.0,
    maxRepsRecord: {},
    chartData: [],
    bmiWeightData: [],
  );
}

/// Entity untuk feedback performa.
class PerformanceFeedback {
  final String title;
  final String message;
  final Color color;
  final IconData icon;

  const PerformanceFeedback({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });
}
