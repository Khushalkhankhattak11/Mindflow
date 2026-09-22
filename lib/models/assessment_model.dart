enum Feeling {
  happy,
  calm,
  stressed,
  sad,
  anxious,
  angry,
  tired,
  overwhelmed,
  motivated,
  grateful,
  distracted,
  lonely,
}

enum StressLevel {
  low,
  medium,
  high,
  veryHigh,
}

enum SleepQuality {
  excellent,
  good,
  average,
  poor,
  veryPoor,
}

enum MindGoal {
  reduceStress,
  sleepBetter,
  focusMore,
  buildHabit,
}

enum CommitmentTime {
  threeMin,
  fiveMin,
  tenMin,
  fifteenMin,
  twentyMin,
  thirtyPlusMin,
}

class AssessmentResponse {
  final Feeling? feeling;
  final StressLevel? stressLevel;
  final SleepQuality? sleepQuality;
  final MindGoal? goal;
  final CommitmentTime? commitment;

  const AssessmentResponse({
    this.feeling,
    this.stressLevel,
    this.sleepQuality,
    this.goal,
    this.commitment,
  });

  AssessmentResponse copyWith({
    Feeling? feeling,
    StressLevel? stressLevel,
    SleepQuality? sleepQuality,
    MindGoal? goal,
    CommitmentTime? commitment,
  }) {
    return AssessmentResponse(
      feeling: feeling ?? this.feeling,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      goal: goal ?? this.goal,
      commitment: commitment ?? this.commitment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feeling': feeling?.name,
      'stressLevel': stressLevel?.name,
      'sleepQuality': sleepQuality?.name,
      'goal': goal?.name,
      'commitment': commitment?.name,
    };
  }

  factory AssessmentResponse.fromMap(Map<String, dynamic> map) {
    var feelingStr = map['feeling'];
    if (feelingStr == 'relaxed') {
      feelingStr = 'calm';
    }
    return AssessmentResponse(
      feeling: _parseEnum(Feeling.values, feelingStr),
      stressLevel: _parseEnum(StressLevel.values, map['stressLevel']),
      sleepQuality: _parseEnum(SleepQuality.values, map['sleepQuality']),
      goal: _parseEnum(MindGoal.values, map['goal']),
      commitment: _parseEnum(CommitmentTime.values, map['commitment']),
    );
  }

  static T? _parseEnum<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    try {
      return values.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }
}
