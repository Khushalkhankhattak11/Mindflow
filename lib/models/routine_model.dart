import 'package:flutter/material.dart';

class RoutineItem {
  final String title;
  final String description;
  final String timeLabel;
  final String period; // "Morning", "Afternoon", "Night"
  final IconData icon;
  final Color color;

  const RoutineItem({
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.period,
    required this.icon,
    required this.color,
  });
}
