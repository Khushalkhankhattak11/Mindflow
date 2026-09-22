import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/onboarding_model.dart';
import '../models/assessment_model.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';

class OnboardingRepository {
  final FirebaseService _firebaseService;
  final DeviceService _deviceService;
  final FirebaseFirestore? _customFirestore;

  OnboardingRepository({
    required this._firebaseService,
    required this._deviceService,
    FirebaseFirestore? firestore,
  })  : _customFirestore = firestore;

  bool get _isActive => _firebaseService.isInitialized;

  FirebaseFirestore get _firestore {
    if (_customFirestore != null) return _customFirestore;
    return FirebaseFirestore.instance;
  }

  /// Increments the app open count for the current device on startup
  Future<void> incrementAppOpenCount() async {
    if (!_isActive) return;
    try {
      final deviceId = await _deviceService.getUniqueDeviceId();
      final docRef = _firestore.collection('unregistered_onboarding').doc(deviceId);
      
      final doc = await docRef.get();
      final now = DateTime.now();
      if (doc.exists && doc.data() != null) {
        final existing = OnboardingData.fromMap(doc.data()!);
        final updated = existing.copyWith(
          appLaunchCount: existing.appLaunchCount + 1,
          lastActive: now,
        ).recordVisit('WelcomeScreen'); // Increment open visits for WelcomeScreen
        
        await docRef.set(updated.toMap());
      } else {
        // Initial setup
        final data = OnboardingData(
          deviceId: deviceId,
          appLaunchCount: 1,
          firstActive: now,
          lastActive: now,
          lastScreen: 'WelcomeScreen',
          register: false,
          screensVisited: [
            OnboardingScreenVisit(screen: 'WelcomeScreen', timestamp: now, visited: 1)
          ],
          screenDurations: [],
          selectedAnswers: {},
        );
        await docRef.set(data.toMap());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing app open count: $e');
      }
    }
  }

  /// Saves the current unregistered user onboarding state to Firestore
  Future<void> saveUnregisteredOnboarding(OnboardingData data) async {
    if (!_isActive) return;
    try {
      final docRef = _firestore.collection('unregistered_onboarding').doc(data.deviceId);
      await docRef.set(data.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving unregistered onboarding data: $e');
      }
    }
  }

  /// Retrieves the unregistered user onboarding data for this device
  Future<OnboardingData?> getUnregisteredOnboarding() async {
    if (!_isActive) return null;
    try {
      final deviceId = await _deviceService.getUniqueDeviceId();
      final doc = await _firestore.collection('unregistered_onboarding').doc(deviceId).get();
      if (doc.exists && doc.data() != null) {
        return OnboardingData.fromMap(doc.data()!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unregistered onboarding data: $e');
      }
    }
    return null;
  }

  /// Transfers the onboarding data from unregistered_onboarding to registered_onboarding
  /// and deletes the unregistered onboarding data for this device.
  Future<void> transferOnboardingToRegistered(String uid) async {
    if (!_isActive) return;
    try {
      final deviceId = await _deviceService.getUniqueDeviceId();
      final docRefUnregistered = _firestore.collection('unregistered_onboarding').doc(deviceId);
      final docRefRegistered = _firestore.collection('registered_onboarding').doc(uid);

      final doc = await docRefUnregistered.get();
      if (doc.exists && doc.data() != null) {
        final existing = OnboardingData.fromMap(doc.data()!);
        // Set register flag to true
        final registeredData = existing.copyWith(register: true);
        
        // Transfer data under registered user uid
        await docRefRegistered.set(registeredData.toMap(), SetOptions(merge: true));
        // Remove from unregistered onboarding
        await docRefUnregistered.delete();
        if (kDebugMode) {
          print('Successfully transferred onboarding data from device $deviceId to user $uid');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error transferring onboarding data: $e');
      }
    }
  }

  /// Retrieves user assessment response (onboarding answers)
  Future<AssessmentResponse?> fetchUserAssessment() async {
    if (!_isActive) return null;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('registered_onboarding').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = OnboardingData.fromMap(doc.data()!);
          return AssessmentResponse.fromMap(data.selectedAnswers);
        }
      }
      final deviceId = await _deviceService.getUniqueDeviceId();
      final doc = await _firestore.collection('unregistered_onboarding').doc(deviceId).get();
      if (doc.exists && doc.data() != null) {
        final data = OnboardingData.fromMap(doc.data()!);
        return AssessmentResponse.fromMap(data.selectedAnswers);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user assessment response: $e');
      }
    }
    return null;
  }
}
