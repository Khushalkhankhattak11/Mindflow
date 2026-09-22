import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../services/service_locator.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = locator<AuthRepository>();

  String _name = '';
  String _email = '';
  String _password = '';
  bool _termsAccepted = false;
  bool _isSubmitting = false;
  bool _isEmailSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _isComplete = false;
  bool _resetSent = false;
  String? _errorMessage;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  bool get termsAccepted => _termsAccepted;
  bool get isSubmitting => _isSubmitting;
  bool get isEmailSubmitting => _isEmailSubmitting;
  bool get isGoogleSubmitting => _isGoogleSubmitting;
  bool get isComplete => _isComplete;
  bool get resetSent => _resetSent;
  String? get errorMessage => _errorMessage;

  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val.trim();
    notifyListeners();
  }

  void setPassword(String val) {
    _password = val;
    notifyListeners();
  }

  void setTermsAccepted(bool val) {
    _termsAccepted = val;
    notifyListeners();
  }

  bool get isEmailValid {
    if (_email.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(_email);
  }

  bool get isPasswordValid {
    return _password.length >= 6;
  }

  bool get canSubmitSignup {
    return _name.isNotEmpty && isEmailValid && isPasswordValid && _termsAccepted;
  }

  bool get canSubmitLogin {
    return isEmailValid && isPasswordValid;
  }

  bool get canSubmitReset {
    return isEmailValid;
  }

  Future<void> submitSignup() async {
    if (!canSubmitSignup || _isSubmitting) return;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signUp(_email, _password, _name);
      final uid = _authRepository.currentUserModel?.uid;
      if (uid != null) {
        await locator<OnboardingRepository>().transferOnboardingToRegistered(uid);
      }
      _isSubmitting = false;
      _isComplete = true;
      notifyListeners();
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = _getCleanErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> submitLogin() async {
    if (!canSubmitLogin || _isSubmitting) return;

    _isSubmitting = true;
    _isEmailSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(_email, _password);
      final uid = _authRepository.currentUserModel?.uid;
      if (uid != null) {
        await locator<OnboardingRepository>().transferOnboardingToRegistered(uid);
      }
      _isSubmitting = false;
      _isEmailSubmitting = false;
      _isComplete = true;
      notifyListeners();
    } catch (e) {
      _isSubmitting = false;
      _isEmailSubmitting = false;
      _errorMessage = _getCleanErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isSubmitting) return;

    _isSubmitting = true;
    _isGoogleSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential != null) {
        final uid = credential.user?.uid;
        if (uid != null) {
          await locator<OnboardingRepository>().transferOnboardingToRegistered(uid);
        }
        _isComplete = true;
      }
      _isSubmitting = false;
      _isGoogleSubmitting = false;
      notifyListeners();
    } catch (e) {
      _isSubmitting = false;
      _isGoogleSubmitting = false;
      _errorMessage = _getCleanErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> submitReset() async {
    if (!canSubmitReset || _isSubmitting) return;

    _isSubmitting = true;
    _resetSent = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordReset(_email);
      _isSubmitting = false;
      _resetSent = true;
      notifyListeners();
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = _getCleanErrorMessage(e);
      notifyListeners();
    }
  }

  void clearComplete() {
    _isComplete = false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getCleanErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'This email address is already in use by another account.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak (must be at least 6 characters).';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'Sign-in provider is disabled. Enable email/password in Firebase Console.';
        default:
          return error.message ?? 'An unexpected authentication error occurred.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
