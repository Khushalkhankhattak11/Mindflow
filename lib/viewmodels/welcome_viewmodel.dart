import 'package:flutter/foundation.dart';
import '../models/welcome_model.dart';
import '../models/onboarding_model.dart';
import '../repositories/onboarding_repository.dart';
import '../services/device_service.dart';
import '../services/service_locator.dart';

class WelcomeViewModel extends ChangeNotifier {
  final OnboardingRepository _onboardingRepository = locator<OnboardingRepository>();
  WelcomeAction? _selectedAction;
  OnboardingData? _onboardingData;

  WelcomeAction? get selectedAction => _selectedAction;
  OnboardingData? get onboardingData => _onboardingData;

  Future<void> prepareOnboarding() async {
    try {
      _onboardingData = await _onboardingRepository.getUnregisteredOnboarding();
    } catch (_) {}
    
    if (_onboardingData == null) {
      try {
        final deviceId = await locator<DeviceService>().getUniqueDeviceId();
        _onboardingData = OnboardingData(
          deviceId: deviceId,
          appLaunchCount: 1,
          firstActive: DateTime.now(),
          lastActive: DateTime.now(),
          lastScreen: 'WelcomeScreen',
          register: false,
          screensVisited: [
            OnboardingScreenVisit(screen: 'WelcomeScreen', timestamp: DateTime.now(), visited: 1)
          ],
          screenDurations: [],
          selectedAnswers: {},
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  void selectAction(WelcomeAction action) {
    _selectedAction = action;
    notifyListeners();
  }

  void clearAction() {
    _selectedAction = null;
  }
}
