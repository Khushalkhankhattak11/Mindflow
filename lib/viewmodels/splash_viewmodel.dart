import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/splash_model.dart';
import '../models/onboarding_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../services/service_locator.dart';

class SplashViewModel extends ChangeNotifier {
  final OnboardingRepository _onboardingRepository = locator<OnboardingRepository>();
  
  SplashState _state = const SplashState(
    status: SplashStatus.loading,
    message: 'Aligning Focus',
  );

  OnboardingData? _onboardingData;

  SplashState get state => _state;

  bool get isLoading => _state.status == SplashStatus.loading;
  bool get isCompleted => _state.status == SplashStatus.completed;

  bool get shouldNavigateToHome => locator<AuthRepository>().isLoggedIn;
  
  OnboardingData? get onboardingData => _onboardingData;

  bool get hasOnboardingProgress {
    final data = _onboardingData;
    if (data == null) return false;
    final ls = data.lastScreen;
    return ls == 'FeelingScreen' ||
        ls == 'StressScreen' ||
        ls == 'SleepScreen' ||
        ls == 'GoalScreen' ||
        ls == 'CommitmentScreen';
  }

  bool get shouldNavigateToLogin {
    final data = _onboardingData;
    if (data == null) return false;
    final ls = data.lastScreen;
    return ls == 'LoginScreen' || ls == 'WellnessPlanScreen';
  }

  Future<void> startInitialization() async {
    final startTime = DateTime.now();

    // 1. Increment app open count
    try {
      await _onboardingRepository.incrementAppOpenCount();
    } catch (_) {}

    // 2. Fetch unregistered onboarding data
    try {
      _onboardingData = await _onboardingRepository.getUnregisteredOnboarding();
    } catch (_) {}

    // 3. Ensure splash display lasts at least 3 seconds for animation smoothness
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final delay = 3000 - elapsed;
    if (delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }

    _state = const SplashState(
      status: SplashStatus.completed,
      message: 'Focused',
    );
    notifyListeners();
  }
}
