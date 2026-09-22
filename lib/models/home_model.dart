class HomeData {
  final String userName;
  final double dailyProgress; // e.g., 0.75 for 75%
  final List<double> chartData; // 7 activity bar heights
  final int streakDays;
  final List<bool> streakHistory; // 5 weekday indicators (completed or not)
  final int activeMoodIndex; // 0: Low, 1: Neutral, 2: Good, 3: Great
  final String activeFeeling;

  const HomeData({
    required this.userName,
    required this.dailyProgress,
    required this.chartData,
    required this.streakDays,
    required this.streakHistory,
    required this.activeMoodIndex,
    required this.activeFeeling,
  });

  HomeData copyWith({
    String? userName,
    double? dailyProgress,
    List<double>? chartData,
    int? streakDays,
    List<bool>? streakHistory,
    int? activeMoodIndex,
    String? activeFeeling,
  }) {
    return HomeData(
      userName: userName ?? this.userName,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      chartData: chartData ?? this.chartData,
      streakDays: streakDays ?? this.streakDays,
      streakHistory: streakHistory ?? this.streakHistory,
      activeMoodIndex: activeMoodIndex ?? this.activeMoodIndex,
      activeFeeling: activeFeeling ?? this.activeFeeling,
    );
  }
}
