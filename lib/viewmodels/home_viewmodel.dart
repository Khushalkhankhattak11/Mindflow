import 'dart:async';
import 'package:flutter/material.dart';
import '../models/home_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/app_logger.dart';
import '../services/service_locator.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  HomeData _data;
  int _activeTab = 0; // 0: Home, 1: Meditate, 2: Sleep, 3: Profile
  StreamSubscription? _userModelSubscription;

  HomeViewModel({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepository = authRepository ?? locator<AuthRepository>(),
        _userRepository = userRepository ?? locator<UserRepository>(),
        _data = const HomeData(
          userName: 'MindFlow User',
          dailyProgress: 0.75,
          chartData: [0.4, 0.6, 0.3, 0.8, 0.45, 0.95, 0.2],
          streakDays: 0,
          streakHistory: [false, false, false, false, false],
          activeMoodIndex: 2, // Default to Good (Index 2)
          activeFeeling: 'happy', // Default to Happy
        ) {
    _loadUserData();
    _userModelSubscription = _authRepository.userModelStream.listen((userModel) {
      if (userModel != null) {
        _updateDataFromModel(userModel);
      }
    });
  }

  HomeData get data => _data;
  int get activeTab => _activeTab;

  /// Returns true if the user currently holds active subscription access.
  /// If the subscription has reached its expiration date, returns false (locks features immediately)
  /// and kicks off background synchronization with Firestore.
  bool get isPremium {
    final userModel = _authRepository.currentUserModel;
    if (userModel == null) return false;
    final active = userModel.isSubscriptionActive;
    if (userModel.isPremium && !active) {
      unawaited(_authRepository.checkAndSyncSubscription());
    }
    return active;
  }

  String? _selectedSleepSoundTitle;
  String? get selectedSleepSoundTitle => _selectedSleepSoundTitle;
  set selectedSleepSoundTitle(String? value) {
    _selectedSleepSoundTitle = value;
    notifyListeners();
  }

  Future<void> setPremiumStatus(
    bool isPremium, {
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? subscriptionStatus,
    String? subscriptionPlan,
    String? subscriptionStore,
    bool? willRenew,
  }) async {
    await _authRepository.setPremiumStatus(
      isPremium,
      purchaseDate: purchaseDate,
      expirationDate: expirationDate,
      subscriptionStatus: subscriptionStatus,
      subscriptionPlan: subscriptionPlan,
      subscriptionStore: subscriptionStore,
      willRenew: willRenew,
    );
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final userModel = _authRepository.currentUserModel;
    if (userModel == null) return;

    _updateDataFromModel(userModel);

    try {
      // 1. Try to fetch user's manual feeling preference from UserRepository
      String? feeling = await _userRepository.getUserFeeling(userModel.uid);

      // 2. If not set, try to get from onboarding
      feeling ??= await _userRepository.getOnboardingFeeling(userModel.uid);

      if (feeling != null) {
        final moodIndex = _mapFeelingToMoodIndex(feeling);
        _data = _data.copyWith(
          activeMoodIndex: moodIndex,
          activeFeeling: feeling,
        );
        notifyListeners();
      }
    } catch (e, stackTrace) {
      AppLogger.w('Error loading user feeling data in HomeViewModel', e, stackTrace);
    }
  }

  int _mapFeelingToMoodIndex(String feeling) {
    switch (feeling) {
      case 'stressed':
      case 'anxious':
      case 'overwhelmed':
      case 'low':
      case 'sad':
      case 'angry':
      case 'lonely':
        return 0; // Low
      case 'relaxed':
      case 'calm':
      case 'tired':
      case 'neutral':
      case 'distracted':
        return 1; // Neutral
      case 'happy':
      case 'good':
      case 'motivated':
        return 2; // Good
      case 'great':
      case 'grateful':
        return 3; // Great
      default:
        return 2; // Default to Good
    }
  }

  String _mapMoodIndexToFeeling(int index) {
    switch (index) {
      case 0:
        return 'stressed';
      case 1:
        return 'calm';
      case 2:
        return 'happy';
      case 3:
        return 'grateful';
      default:
        return 'happy';
    }
  }

  Future<void> selectMood(int index) async {
    if (index >= 0 && index < 4) {
      final feeling = _mapMoodIndexToFeeling(index);
      await selectFeeling(feeling);
    }
  }

  Future<void> selectFeeling(String feeling) async {
    final moodIndex = _mapFeelingToMoodIndex(feeling);
    _data = _data.copyWith(
      activeMoodIndex: moodIndex,
      activeFeeling: feeling,
    );
    notifyListeners();

    // Save using UserRepository
    final userModel = _authRepository.currentUserModel;
    if (userModel != null) {
      try {
        await _userRepository.updateUserFeeling(userModel.uid, feeling);
      } catch (e, stackTrace) {
        AppLogger.e('Error saving user feeling in selectFeeling', e, stackTrace);
      }
    }
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void _updateDataFromModel(UserModel userModel) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final streakHistory = <bool>[];

    for (int i = 4; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      if (date.isBefore(DateTime(userModel.createdAt.year, userModel.createdAt.month, userModel.createdAt.day))) {
        streakHistory.add(false);
      } else {
        final isMissed = userModel.streakMissed.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        
        final lastActive = userModel.lastActiveDate;
        final isActive = !isMissed &&
            (lastActive != null &&
                (date.isBefore(lastActive) ||
                    (date.year == lastActive.year &&
                        date.month == lastActive.month &&
                        date.day == lastActive.day)));
        streakHistory.add(isActive);
      }
    }

    _data = _data.copyWith(
      userName: userModel.name,
      streakDays: userModel.dayStreak,
      streakHistory: streakHistory,
    );
    notifyListeners();
  }

  String get timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get adaptiveHeroTag {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'MORNING FOCUS';
    if (hour >= 12 && hour < 17) return 'MIDDAY RESET';
    if (hour >= 17 && hour < 21) return 'EVENING CALM';
    return 'DEEP SLEEP';
  }

  String get adaptiveHeroTitle {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning Focus & Clarity';
    if (hour >= 12 && hour < 17) return 'Midday Stress Reset';
    if (hour >= 17 && hour < 21) return 'Evening Relaxation';
    return 'Deep REM Sleep Soundscape';
  }

  String get adaptiveHeroSubtitle {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Prepare your mind with 10 minutes of intentional morning breathing.';
    }
    if (hour >= 12 && hour < 17) {
      return 'Lower cortisol levels and reset your posture for peak afternoon clarity.';
    }
    if (hour >= 17 && hour < 21) {
      return 'Unwind your nervous system and release the day\'s accumulated stress.';
    }
    return 'Drift into restorative sleep with soft midnight ocean waves.';
  }

  String get adaptiveHeroImageUrl {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80';
    }
    if (hour >= 12 && hour < 17) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
    }
    if (hour >= 17 && hour < 21) {
      return 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=800&q=80';
  }

  @override
  void dispose() {
    _userModelSubscription?.cancel();
    super.dispose();
  }
}
