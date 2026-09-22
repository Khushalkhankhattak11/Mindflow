import 'package:flutter/material.dart';
import '../models/routine_model.dart';

class WellnessPlanViewModel extends ChangeNotifier {
  final List<RoutineItem> _routine = const [
    RoutineItem(
      title: '3 Minute Breathing',
      description: 'Kickstart your nervous system with focused breathwork.',
      timeLabel: '08:00 AM',
      period: 'Morning',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFF6B38D4),
    ),
    RoutineItem(
      title: 'Focus Meditation',
      description: 'Re-center your mind during the midday peak energy.',
      timeLabel: '02:00 PM',
      period: 'Afternoon',
      icon: Icons.center_focus_strong,
      color: Color(0xFF6F5092),
    ),
    RoutineItem(
      title: 'Sleep Meditation',
      description: 'Ease into deep, restorative sleep with calming soundscapes.',
      timeLabel: '10:30 PM',
      period: 'Night',
      icon: Icons.bedtime_outlined,
      color: Color(0xFF4E45D5),
    ),
  ];

  List<RoutineItem> get routine => _routine;
}
