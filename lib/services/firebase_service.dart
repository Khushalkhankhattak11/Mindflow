import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      // Initialize Firebase App
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      if (kDebugMode) {
        print('Firebase successfully initialized.');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
        print('Please make sure you have added google-services.json (Android) and GoogleService-Info.plist (iOS).');
      }
    }
  }
}
