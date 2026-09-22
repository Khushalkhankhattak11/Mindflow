import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/meditation_model.dart';
import '../models/assessment_model.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/user_repository.dart';
import '../services/app_logger.dart';
import '../services/service_locator.dart';

class MeditateLibraryViewModel extends ChangeNotifier {
  final OnboardingRepository _onboardingRepository =
      locator<OnboardingRepository>();

  AssessmentResponse? _userAssessment;
  bool _isLoadingAssessment = true;

  AssessmentResponse? get userAssessment => _userAssessment;
  bool get isLoadingAssessment => _isLoadingAssessment;
  bool get hasAssessmentData => _userAssessment != null;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<MeditationSession> _sessions = [
    const MeditationSession(
      title: 'Finding Stillness',
      description:
          'A simple introduction to mindful breathing and presence in the moment.',
      durationLabel: '10m',
      difficulty: 'Beginner',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m1.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Stress', 'Morning', 'Anxiety', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Quick 3-Min Reset',
      description:
          'Ultra-fast micro-meditation to reset your nervous system anywhere.',
      durationLabel: '3m',
      difficulty: 'Beginner',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m2.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Habit', 'Stress', 'Focus', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Cortisol & Anxiety Calm',
      description:
          'Targeted breathing and somatic release designed specifically for high stress levels.',
      durationLabel: '5m',
      difficulty: 'All Levels',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m3.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Stress', 'Anxiety', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Ocean Dreams Sleep',
      description:
          'Drift into deep restorative sleep with the rhythmic sounds of midnight waves.',
      durationLabel: '25m',
      difficulty: 'All Levels',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m4.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Sleep', 'Evening', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Peak Performance Focus',
      description:
          'Harness intense focus through advanced visualization techniques for deep work.',
      durationLabel: '15m',
      difficulty: 'Expert',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m5.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Focus', 'Morning', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Daily Habit Builder',
      description:
          'Consistent 10-minute mental hygiene to build a lasting daily mindfulness habit.',
      durationLabel: '10m',
      difficulty: 'Beginner',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m6.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Habit', 'Morning', 'For You'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Stress Release',
      description:
          'Instantly lower cortisol levels with guided box-breathing exercises.',
      durationLabel: '12m',
      difficulty: 'Beginner',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m7.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Stress', 'Anxiety'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Nighttime Body Scan',
      description: 'Release muscular tension from head to toe before bedtime.',
      durationLabel: '20m',
      difficulty: 'Intermediate',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m8.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Sleep', 'Evening'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Emotional Balance',
      description:
          'A quick session to center yourself during overwhelming emotional moments.',
      durationLabel: '8m',
      difficulty: 'All Levels',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m9.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Anxiety', 'Evening', 'Stress'],
      isFavorited: false,
    ),
    const MeditationSession(
      title: 'Mindful Gratitude Flow',
      description:
          'Cultivate deep appreciation and positivity with guided gratitude reflections.',
      durationLabel: '15m',
      difficulty: 'Beginner',
      imageUrl:
          'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m10.png',
      instructorName: 'Admin',
      instructorAvatars: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
      ],
      categories: ['Habit', 'Focus', 'For You'],
      isFavorited: false,
    ),
  ];

  final UserRepository _userRepository = locator<UserRepository>();

  MeditateLibraryViewModel() {
    _loadUserAssessmentAndFavorites();
  }

  Future<void> _loadUserAssessmentAndFavorites() async {
    _isLoadingAssessment = true;
    notifyListeners();

    try {
      _userAssessment = await _onboardingRepository.fetchUserAssessment();
    } catch (_) {}

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final favTitles = await _userRepository.getFavoriteSessionTitles(uid);
        if (favTitles.isNotEmpty) {
          _sessions = _sessions.map((session) {
            final isFav = favTitles.contains(session.title);
            return session.copyWith(isFavorited: isFav);
          }).toList();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.w('Failed to load user favorites from Firestore', e, stackTrace);
    }

    _isLoadingAssessment = false;
    notifyListeners();
  }

  List<MeditationSession> get sessions => _sessions;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<MeditationSession> get favoritedSessions =>
      _sessions.where((session) => session.isFavorited).toList();

  void toggleFavorite(String title) {
    bool isNowFavorited = false;
    _sessions = _sessions.map((session) {
      if (session.title == title) {
        isNowFavorited = !session.isFavorited;
        return session.copyWith(isFavorited: isNowFavorited);
      }
      return session;
    }).toList();
    notifyListeners();

    // Persist dynamically in Firestore under users/{uid} collection array
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      if (isNowFavorited) {
        unawaited(_userRepository.addFavoriteSession(uid, title));
      } else {
        unawaited(_userRepository.removeFavoriteSession(uid, title));
      }
    }
  }

  // User Onboarding Goal text label
  String get onboardingGoalLabel {
    if (_userAssessment?.goal != null) {
      switch (_userAssessment!.goal!) {
        case MindGoal.reduceStress:
          return 'Reduce Stress';
        case MindGoal.sleepBetter:
          return 'Sleep Better';
        case MindGoal.focusMore:
          return 'Improve Focus';
        case MindGoal.buildHabit:
          return 'Build Daily Habit';
      }
    }
    return 'Reduce Stress';
  }

  // User Onboarding Feeling text label
  String get onboardingFeelingLabel {
    if (_userAssessment?.feeling != null) {
      final name = _userAssessment!.feeling!.name;
      return name[0].toUpperCase() + name.substring(1);
    }
    return 'Calm';
  }

  // User Onboarding Preferred Commitment Duration label
  String get onboardingTimeLabel {
    if (_userAssessment?.commitment != null) {
      switch (_userAssessment!.commitment!) {
        case CommitmentTime.threeMin:
          return '3 mins';
        case CommitmentTime.fiveMin:
          return '5 mins';
        case CommitmentTime.tenMin:
          return '10 mins';
        case CommitmentTime.fifteenMin:
          return '15 mins';
        case CommitmentTime.twentyMin:
          return '20 mins';
        case CommitmentTime.thirtyPlusMin:
          return '30+ mins';
      }
    }
    return '10 mins';
  }

  /// Get list of sessions specifically curated for the user's onboarding goal & feeling
  List<MeditationSession> get recommendedSessions {
    final goalTag = _mapGoalToCategory(_userAssessment?.goal);
    final feelingTag = _mapFeelingToCategory(_userAssessment?.feeling);

    return _sessions.where((session) {
      final matchesGoal =
          goalTag == null || session.categories.contains(goalTag);
      final matchesFeeling =
          feelingTag == null || session.categories.contains(feelingTag);
      final isTaggedForYou = session.categories.contains('For You');
      return matchesGoal || matchesFeeling || isTaggedForYou;
    }).toList();
  }

  String? _mapGoalToCategory(MindGoal? goal) {
    if (goal == null) return 'Stress';
    switch (goal) {
      case MindGoal.reduceStress:
        return 'Stress';
      case MindGoal.sleepBetter:
        return 'Sleep';
      case MindGoal.focusMore:
        return 'Focus';
      case MindGoal.buildHabit:
        return 'Habit';
    }
  }

  String? _mapFeelingToCategory(Feeling? feeling) {
    if (feeling == null) return null;
    switch (feeling) {
      case Feeling.stressed:
      case Feeling.anxious:
      case Feeling.overwhelmed:
      case Feeling.angry:
        return 'Anxiety';
      case Feeling.tired:
      case Feeling.sad:
      case Feeling.lonely:
        return 'Sleep';
      case Feeling.distracted:
      case Feeling.motivated:
        return 'Focus';
      case Feeling.happy:
      case Feeling.calm:
      case Feeling.grateful:
        return 'Morning';
    }
  }

  List<MeditationSession> get filteredSessions {
    return _sessions.where((session) {
      // 1. Category Filter
      bool matchesCategory = true;
      if (_selectedCategory == 'For You') {
        final recs = recommendedSessions;
        matchesCategory = recs.contains(session);
      } else if (_selectedCategory != 'All') {
        matchesCategory = session.categories.contains(_selectedCategory);
      }

      // 2. Search Query Filter
      final matchesQuery =
          _searchQuery.isEmpty ||
          session.title.toLowerCase().contains(_searchQuery) ||
          session.description.toLowerCase().contains(_searchQuery) ||
          session.instructorName.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }
}
