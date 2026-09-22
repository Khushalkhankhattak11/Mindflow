import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreenVisit {
  final String screen;
  final DateTime timestamp;
  final int visited;

  const OnboardingScreenVisit({
    required this.screen,
    required this.timestamp,
    required this.visited,
  });

  Map<String, dynamic> toMap() {
    return {
      'screen': screen,
      'timestamp': Timestamp.fromDate(timestamp),
      'visited': visited,
    };
  }

  factory OnboardingScreenVisit.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['timestamp'] is Timestamp) {
      parsedDate = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedDate = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return OnboardingScreenVisit(
      screen: map['screen'] as String? ?? '',
      timestamp: parsedDate,
      visited: (map['visited'] as num?)?.toInt() ?? 0,
    );
  }
}

class OnboardingScreenDuration {
  final String screen;
  final DateTime timestamp;
  final int durationSeconds;

  const OnboardingScreenDuration({
    required this.screen,
    required this.timestamp,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'screen': screen,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': durationSeconds,
    };
  }

  factory OnboardingScreenDuration.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['timestamp'] is Timestamp) {
      parsedDate = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedDate = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return OnboardingScreenDuration(
      screen: map['screen'] as String? ?? '',
      timestamp: parsedDate,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class OnboardingData {
  final String deviceId;
  final int appLaunchCount;
  final DateTime firstActive;
  final DateTime lastActive;
  final String lastScreen;
  final bool register;
  final List<OnboardingScreenVisit> screensVisited;
  final List<OnboardingScreenDuration> screenDurations;
  final Map<String, dynamic> selectedAnswers;

  const OnboardingData({
    required this.deviceId,
    required this.appLaunchCount,
    required this.firstActive,
    required this.lastActive,
    required this.lastScreen,
    required this.register,
    required this.screensVisited,
    required this.screenDurations,
    required this.selectedAnswers,
  });

  OnboardingData recordVisit(String screenName) {
    final now = DateTime.now();
    final updatedVisits = List<OnboardingScreenVisit>.from(screensVisited);
    final index = updatedVisits.indexWhere((e) => e.screen == screenName);

    if (index >= 0) {
      final old = updatedVisits[index];
      updatedVisits[index] = OnboardingScreenVisit(
        screen: screenName,
        timestamp: now,
        visited: old.visited + 1,
      );
    } else {
      updatedVisits.add(OnboardingScreenVisit(
        screen: screenName,
        timestamp: now,
        visited: 1,
      ));
    }

    return copyWith(
      lastActive: now,
      lastScreen: screenName,
      screensVisited: updatedVisits,
    );
  }

  OnboardingData recordDuration(String screenName, int seconds) {
    final now = DateTime.now();
    final updatedDurations = List<OnboardingScreenDuration>.from(screenDurations);
    final index = updatedDurations.indexWhere((e) => e.screen == screenName);

    if (index >= 0) {
      final old = updatedDurations[index];
      updatedDurations[index] = OnboardingScreenDuration(
        screen: screenName,
        timestamp: now,
        durationSeconds: old.durationSeconds + seconds,
      );
    } else {
      updatedDurations.add(OnboardingScreenDuration(
        screen: screenName,
        timestamp: now,
        durationSeconds: seconds,
      ));
    }

    return copyWith(
      lastActive: now,
      screenDurations: updatedDurations,
    );
  }

  OnboardingData copyWith({
    String? deviceId,
    int? appLaunchCount,
    DateTime? firstActive,
    DateTime? lastActive,
    String? lastScreen,
    bool? register,
    List<OnboardingScreenVisit>? screensVisited,
    List<OnboardingScreenDuration>? screenDurations,
    Map<String, dynamic>? selectedAnswers,
  }) {
    return OnboardingData(
      deviceId: deviceId ?? this.deviceId,
      appLaunchCount: appLaunchCount ?? this.appLaunchCount,
      firstActive: firstActive ?? this.firstActive,
      lastActive: lastActive ?? this.lastActive,
      lastScreen: lastScreen ?? this.lastScreen,
      register: register ?? this.register,
      screensVisited: screensVisited ?? List<OnboardingScreenVisit>.from(this.screensVisited),
      screenDurations: screenDurations ?? List<OnboardingScreenDuration>.from(this.screenDurations),
      selectedAnswers: selectedAnswers ?? Map<String, dynamic>.from(this.selectedAnswers),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'appLaunchCount': appLaunchCount,
      'firstActive': Timestamp.fromDate(firstActive),
      'lastActive': Timestamp.fromDate(lastActive),
      'lastScreen': lastScreen,
      'register': register,
      'screensVisited': screensVisited.map((e) => e.toMap()).toList(),
      'screenDurations': screenDurations.map((e) => e.toMap()).toList(),
      'selectedAnswers': selectedAnswers,
    };
  }

  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawVisits = map['screensVisited'] as List? ?? [];
    final visits = rawVisits.map((e) => OnboardingScreenVisit.fromMap(Map<String, dynamic>.from(e as Map))).toList();

    final rawDurations = map['screenDurations'] as List? ?? [];
    final durations = rawDurations.map((e) => OnboardingScreenDuration.fromMap(Map<String, dynamic>.from(e as Map))).toList();

    return OnboardingData(
      deviceId: map['deviceId'] as String? ?? '',
      appLaunchCount: (map['appLaunchCount'] as num?)?.toInt() ?? 0,
      firstActive: parseTime(map['firstActive']),
      lastActive: parseTime(map['lastActive']),
      lastScreen: map['lastScreen'] as String? ?? '',
      register: map['register'] as bool? ?? false,
      screensVisited: visits,
      screenDurations: durations,
      selectedAnswers: Map<String, dynamic>.from(map['selectedAnswers'] as Map? ?? {}),
    );
  }
}
