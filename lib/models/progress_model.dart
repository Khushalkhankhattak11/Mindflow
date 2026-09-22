class MilestoneItem {
  final String title;
  final String description;
  final double progress; // e.g. 0.9
  final bool isUnlocked;
  final String imageUrl;

  const MilestoneItem({
    required this.title,
    required this.description,
    required this.progress,
    required this.isUnlocked,
    required this.imageUrl,
  });
}

class ProgressData {
  final double dailyGoalPercentage; // 0.8 (80%)
  final int completedMinutes; // 12
  final int goalMinutes; // 15
  final int totalMeditationMinutes; // 450
  final int streakDays; // 12
  final int completedSessions; // 28
  final List<double> weeklyMinutes; // [32, 28, 36, 48, 40, 52, 44]
  final List<MilestoneItem> milestones;

  const ProgressData({
    required this.dailyGoalPercentage,
    required this.completedMinutes,
    required this.goalMinutes,
    required this.totalMeditationMinutes,
    required this.streakDays,
    required this.completedSessions,
    required this.weeklyMinutes,
    required this.milestones,
  });
}
