import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FcmService {
  final FirebaseService _firebaseService;
  final FirebaseMessaging? _customMessaging;

  FcmService({
    required this._firebaseService,
    FirebaseMessaging? messaging,
  })  : _customMessaging = messaging;

  bool get _isActive => _firebaseService.isInitialized;

  FirebaseMessaging get _messaging {
    if (_customMessaging != null) return _customMessaging;
    return FirebaseMessaging.instance;
  }

  Future<void> requestPermission() async {
    if (!_isActive) return;
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await subscribeToTopic('all_users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_isActive) return;
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to FCM topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  Future<String?> getFcmToken() async {
    if (!_isActive) return null;
    try {
      // In some iOS environments, APNs needs to be configured, otherwise getToken throws
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FCM Token: $e');
      }
      return null;
    }
  }

  Stream<String> get onTokenRefresh {
    if (!_isActive) return const Stream.empty();
    return _messaging.onTokenRefresh;
  }
}
