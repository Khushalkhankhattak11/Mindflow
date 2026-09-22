import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/assessment_model.dart';
import '../models/onboarding_model.dart';
import '../repositories/onboarding_repository.dart';
import '../services/service_locator.dart';

class AssessmentViewModel extends ChangeNotifier {
  final OnboardingRepository _onboardingRepository = locator<OnboardingRepository>();

  int _currentStep;
  AssessmentResponse _response;
  bool _isSubmitting = false;
  bool _isComplete = false;

  OnboardingData _onboardingData;
  DateTime? _stepStartTime;

  AssessmentViewModel({
    required OnboardingData onboardingData,
  })  : _onboardingData = onboardingData,
        _currentStep = _mapScreenToStep(onboardingData.lastScreen),
        _response = AssessmentResponse.fromMap(onboardingData.selectedAnswers) {
    final screenName = _mapStepToScreen(_currentStep);
    _onboardingData = _onboardingData.recordVisit(screenName);
    _startStepTimer();
    _syncOnboardingToFirestore();
  }

  int get currentStep => _currentStep;
  AssessmentResponse get response => _response;
  bool get isSubmitting => _isSubmitting;
  bool get isComplete => _isComplete;
  OnboardingData get onboardingData => _onboardingData;

  double get progressPercentage => _currentStep / 5;

  bool get canContinue {
    switch (_currentStep) {
      case 1:
        return _response.feeling != null;
      case 2:
        return _response.stressLevel != null;
      case 3:
        return _response.sleepQuality != null;
      case 4:
        return _response.goal != null;
      case 5:
        return _response.commitment != null;
      default:
        return false;
    }
  }

  static int _mapScreenToStep(String screen) {
    switch (screen) {
      case 'FeelingScreen':
        return 1;
      case 'StressScreen':
        return 2;
      case 'SleepScreen':
        return 3;
      case 'GoalScreen':
        return 4;
      case 'CommitmentScreen':
        return 5;
      default:
        return 1;
    }
  }

  static String _mapStepToScreen(int step) {
    switch (step) {
      case 1:
        return 'FeelingScreen';
      case 2:
        return 'StressScreen';
      case 3:
        return 'SleepScreen';
      case 4:
        return 'GoalScreen';
      case 5:
        return 'CommitmentScreen';
      default:
        return 'FeelingScreen';
    }
  }

  void _startStepTimer() {
    _stepStartTime = DateTime.now();
  }

  void _accumulateTimeForStep(int step) {
    if (_stepStartTime != null) {
      final seconds = DateTime.now().difference(_stepStartTime!).inSeconds;
      final screenName = _mapStepToScreen(step);
      // Ensure at least 1 second is counted if they transitioned quickly
      _onboardingData = _onboardingData.recordDuration(screenName, seconds > 0 ? seconds : 1);
    }
  }

  Future<void> _syncOnboardingToFirestore() async {
    await _onboardingRepository.saveUnregisteredOnboarding(_onboardingData);
  }

  void selectFeeling(Feeling feeling) {
    _response = _response.copyWith(feeling: feeling);
    _onboardingData = _onboardingData.copyWith(
      selectedAnswers: _response.toMap(),
    );
    notifyListeners();
    _syncOnboardingToFirestore();
  }

  void selectStressLevel(StressLevel level) {
    _response = _response.copyWith(stressLevel: level);
    _onboardingData = _onboardingData.copyWith(
      selectedAnswers: _response.toMap(),
    );
    notifyListeners();
    _syncOnboardingToFirestore();
  }

  void selectSleepQuality(SleepQuality sleep) {
    _response = _response.copyWith(sleepQuality: sleep);
    _onboardingData = _onboardingData.copyWith(
      selectedAnswers: _response.toMap(),
    );
    notifyListeners();
    _syncOnboardingToFirestore();
  }

  void selectGoal(MindGoal goal) {
    _response = _response.copyWith(goal: goal);
    _onboardingData = _onboardingData.copyWith(
      selectedAnswers: _response.toMap(),
    );
    notifyListeners();
    _syncOnboardingToFirestore();
  }

  void selectCommitment(CommitmentTime commitment) {
    _response = _response.copyWith(commitment: commitment);
    _onboardingData = _onboardingData.copyWith(
      selectedAnswers: _response.toMap(),
    );
    notifyListeners();
    _syncOnboardingToFirestore();
  }

  void nextStep() {
    if (!canContinue) return;

    _accumulateTimeForStep(_currentStep);

    if (_currentStep < 5) {
      _currentStep++;
      final screenName = _mapStepToScreen(_currentStep);
      _onboardingData = _onboardingData.recordVisit(screenName);
      _startStepTimer();
      notifyListeners();
      _syncOnboardingToFirestore();
    } else {
      _submitAssessment();
    }
  }

  void previousStep() {
    if (_currentStep > 1) {
      _accumulateTimeForStep(_currentStep);
      _currentStep--;
      final screenName = _mapStepToScreen(_currentStep);
      _onboardingData = _onboardingData.recordVisit(screenName);
      _startStepTimer();
      notifyListeners();
      _syncOnboardingToFirestore();
    }
  }

  void closeViewModel() {
    _accumulateTimeForStep(_currentStep);
    _syncOnboardingToFirestore();
  }

  void _submitAssessment() {
    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    _accumulateTimeForStep(_currentStep);
    _onboardingData = _onboardingData.copyWith(lastScreen: 'WellnessPlanScreen');
    _syncOnboardingToFirestore();

    // Simulate saving responses to a backend (1.2 seconds delay)
    Timer(const Duration(milliseconds: 1200), () {
      _isSubmitting = false;
      _isComplete = true;
      notifyListeners();
    });
  }
}
