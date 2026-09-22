import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';

class ProgressViewModel extends ChangeNotifier {
  final ProgressData _data = const ProgressData(
    dailyGoalPercentage: 0.80,
    completedMinutes: 12,
    goalMinutes: 15,
    totalMeditationMinutes: 450,
    streakDays: 12,
    completedSessions: 28,
    weeklyMinutes: [32, 28, 36, 48, 40, 52, 44],
    milestones: [
      MilestoneItem(
        title: 'Zen Master',
        description: 'Complete 30 sessions in a month',
        progress: 0.90,
        isUnlocked: false,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDv_nBvbiupcp5HfYoDVaBHQywuzxRlgUkVyoaAIYcrCNaEy-_ps0ouOvQk-wg5wfq-YugAuM3WvMKza9TE1019AoDzDJntXQdAEuszdKHOP1AsZbMiNR5jIe33BDgxDkDhzy_N18Cm7rmJqO0I4Dyka-JENLHfh2WVUl9A7NsuMOuGtMPv9SQchdE8BrDbNxfgYcX_AWJS-MMSAqYyImFfl9wZhdJCGWqJt2qOHNRqJheetzIlDmvm0Q',
      ),
      MilestoneItem(
        title: 'Sun-Seer',
        description: 'Completed 10 day streak',
        progress: 1.0,
        isUnlocked: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCQM7dojNAXeiFFEjGt21W98iDYRfc7aWduBZoeyEpZJXbEcEPrkL17OrKbO1x72Rg-8DVA7V7yleCiMdAaiVeHPlNjomaHjr97TQ7KlD0l5hLrBocwvmdCIRX7-RaSMruvgwONN_v14u8mpQdTNidTu4G3GfbXX_iUvoqmh-HIOtLvcyybRGv0uZ8P3BaGJUN74Enia1F4AvkJF_meXLbUODWxNqWDcxWUvk561A3DkZ8pTHSqOykFKQ',
      ),
    ],
  );

  ProgressData get data => _data;
}
