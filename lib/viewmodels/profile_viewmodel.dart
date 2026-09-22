import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = locator<AuthRepository>();
  StreamSubscription? _userSubscription;

  UserProfile _profile = const UserProfile(
    name: 'Guest User',
    email: '',
    dayStreak: 0,
    sessionsCount: 0,
    mindfulHours: '0.0h',
    isPremium: false,
  );

  bool _isLoggingOut = false;
  bool _isDeleting = false;
  bool _loggedOut = false;

  ProfileViewModel() {
    _init();
  }

  void _init() {
    // Initialize profile with current cached model
    _updateProfile(_authRepository.currentUserModel);

    // Listen to real-time updates from AuthRepository
    _userSubscription = _authRepository.userModelStream.listen((UserModel? userModel) {
      _updateProfile(userModel);
    });
  }

  void _updateProfile(UserModel? userModel) {
    if (userModel == null) {
      _profile = const UserProfile(
        name: 'Guest User',
        email: '',
        dayStreak: 0,
        sessionsCount: 0,
        mindfulHours: '0.0h',
        isPremium: false,
        phone: null,
        biometricEnabled: false,
        photoUrl: null,
      );
    } else {
      _profile = UserProfile(
        name: userModel.name.isNotEmpty ? userModel.name : 'MindFlow User',
        email: userModel.email,
        dayStreak: userModel.dayStreak,
        sessionsCount: userModel.sessionsCount,
        mindfulHours: '${userModel.mindfulHours.toStringAsFixed(1)}h',
        isPremium: userModel.isSubscriptionActive,
        phone: userModel.phone,
        biometricEnabled: userModel.biometricEnabled,
        photoUrl: userModel.photoUrl,
        premiumExpirationDate: userModel.premiumExpirationDate,
        subscriptionStatus: userModel.subscriptionStatus,
        subscriptionPlan: userModel.subscriptionPlan,
      );
    }
    notifyListeners();
  }

  UserProfile get profile => _profile;
  bool get isLoggingOut => _isLoggingOut;
  bool get isDeleting => _isDeleting;
  bool get loggedOut => _loggedOut;

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _isLoggingOut = false;
      _loggedOut = true;
      notifyListeners();
    } catch (_) {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (_isDeleting) return;
    _isDeleting = true;
    notifyListeners();

    try {
      await _authRepository.deleteAccount();
      _isDeleting = false;
      _loggedOut = true;
      notifyListeners();
    } catch (_) {
      _isDeleting = false;
      notifyListeners();
    }
  }

  void clearLoggedOut() {
    _loggedOut = false;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String? phone,
    required bool biometricEnabled,
    required String? photoUrl,
  }) async {
    await _authRepository.updateProfile(
      newName: name,
      newEmail: email,
      newPhone: phone,
      biometricEnabled: biometricEnabled,
      newPhotoUrl: photoUrl,
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _authRepository.updatePassword(currentPassword, newPassword);
  }

  Future<void> submitFeedback({
    required int rating,
    required String thoughts,
  }) async {
    await _authRepository.submitFeedback(
      rating: rating,
      thoughts: thoughts,
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
