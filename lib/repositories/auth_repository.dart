import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/service_locator.dart';
import '../services/app_logger.dart';

class AuthRepository {
  final FirebaseService _firebaseService;
  final AuthService _authService;
  final FcmService _fcmService;
  
  final FirebaseFirestore? _customFirestore;
  UserModel? _currentUserModel;
  StreamSubscription? _authSubscription;
  StreamSubscription? _fcmSubscription;

  final StreamController<UserModel?> _userModelController = StreamController<UserModel?>.broadcast();

  AuthRepository({
    required this._firebaseService,
    required this._authService,
    required this._fcmService,
    FirebaseFirestore? firestore,
  })  : _customFirestore = firestore {
    _initListeners();
  }

  FirebaseFirestore get _firestore {
    if (_customFirestore != null) return _customFirestore;
    return FirebaseFirestore.instance;
  }

  bool get _isActive => _firebaseService.isInitialized;
  
  UserModel? get currentUserModel => _currentUserModel;
  Stream<UserModel?> get userModelStream => _userModelController.stream;
  bool get isLoggedIn => _authService.currentUser != null;

  void _initListeners() {
    if (!_isActive) return;

    // Listen to Firebase Auth state changes
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _currentUserModel = null;
        _userModelController.add(null);
      } else {
        await _fetchAndSyncUserData(user);
      }
    });

    // Listen to FCM token updates and sync to Firestore
    _fcmSubscription = _fcmService.onTokenRefresh.listen((String token) async {
      final user = _authService.currentUser;
      if (user != null) {
        await _updateFcmTokenInFirestore(user.uid, token);
      }
    });

    // Automatically sync RevenueCat CustomerInfo updates (purchases, renewals, cancellations, expiries)
    locator<RevenueCatService>().onCustomerInfoUpdated = (CustomerInfo customerInfo) async {
      await syncSubscriptionFromCustomerInfo(customerInfo);
    };
  }

  Future<void> _fetchAndSyncUserData(User user) async {
    try {
      // 1. Try to fetch existing document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUserModel = UserModel.fromMap(doc.data()!);
        await _checkAndUpdateStreak(user.uid);
      } else {
        // Fallback or create if auth exists but firestore doc is missing
        _currentUserModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'MindFlow User',
          email: user.email ?? '',
          createdAt: DateTime.now(),
          lastActiveDate: DateTime.now(),
          dayStreak: 1,
          streakMissed: const [],
        );
        await _firestore.collection('users').doc(user.uid).set(_currentUserModel!.toMap());
      }

      // 2. Refresh notification permissions and FCM token
      await _fcmService.requestPermission();
      await locator<NotificationService>().requestPermissions();

      // 3. Sync user ID with RevenueCat
      try {
        final rcService = locator<RevenueCatService>();
        if (rcService.isInitialized) {
          await Purchases.logIn(user.uid);
        }
      } catch (e) {
        if (kDebugMode) {
          print('RevenueCat logIn error: $e');
        }
      }

      // 4. Auto-validate and sync subscription status (lock features if expired, unlock if active)
      await checkAndSyncSubscription();

      final token = await _fcmService.getFcmToken();
      if (token != null && token != _currentUserModel?.fcmToken) {
        await _updateFcmTokenInFirestore(user.uid, token);
      } else {
        _userModelController.add(_currentUserModel);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user data: $e');
      }
      // If Firestore fails, provide memory-based User model
      _currentUserModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'MindFlow User',
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );
      _userModelController.add(_currentUserModel);
    }
  }

  Future<void> _updateFcmTokenInFirestore(String uid, String token) async {
    if (!_isActive) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
      });
      if (_currentUserModel != null && _currentUserModel!.uid == uid) {
        _currentUserModel = _currentUserModel!.copyWith(fcmToken: token);
        _userModelController.add(_currentUserModel);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM token in Firestore: $e');
      }
    }
  }

  Future<void> _checkAndUpdateStreak(String uid) async {
    if (_currentUserModel == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastActiveDateVal = _currentUserModel!.lastActiveDate;
    int newStreak = _currentUserModel!.dayStreak;
    List<DateTime> newStreakMissed = List.from(_currentUserModel!.streakMissed);

    if (lastActiveDateVal == null) {
      // First active date
      newStreak = 1;
    } else {
      final lastActive = DateTime(
        lastActiveDateVal.year,
        lastActiveDateVal.month,
        lastActiveDateVal.day,
      );
      final difference = today.difference(lastActive).inDays;

      if (difference == 0) {
        // Already active today, do nothing
        return;
      } else if (difference == 1) {
        // Consecutive day
        newStreak += 1;
      } else {
        // Streak is broken (difference > 1)
        // Record all missed dates in the array!
        for (int i = 1; i < difference; i++) {
          final missedDate = lastActive.add(Duration(days: i));
          newStreakMissed.add(missedDate);
        }
        // Reset streak to 1
        newStreak = 1;
      }
    }

    try {
      if (_isActive) {
        await _firestore.collection('users').doc(uid).update({
          'dayStreak': newStreak,
          'lastActiveDate': Timestamp.fromDate(now),
          'streakMissed': newStreakMissed.map((d) => Timestamp.fromDate(d)).toList(),
        });
      }

      // Update local model
      _currentUserModel = _currentUserModel!.copyWith(
        dayStreak: newStreak,
        lastActiveDate: now,
        streakMissed: newStreakMissed,
      );
      _userModelController.add(_currentUserModel);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating streak in Firestore: $e');
      }
    }
  }

  Future<void> saveQuickExerciseReport({
    required String exerciseName,
    required int durationSeconds,
    required int breathCount,
  }) async {
    final user = _authService.currentUser;
    if (user != null) {
      final reportDoc = {
        'exerciseName': exerciseName,
        'durationSeconds': durationSeconds,
        'breathCount': breathCount,
        'timestamp': FieldValue.serverTimestamp(),
      };
      try {
        if (_isActive) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('quick_exercise_reports')
              .add(reportDoc);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving exercise report: $e');
        }
        rethrow;
      }
    } else {
      throw Exception('No user logged in.');
    }
  }

  Future<void> login(String email, String password) async {
    await _authService.signInWithEmailAndPassword(email, password);
    // User changes are automatically captured by the authStateChanges listener
  }

  Future<UserCredential?> signInWithGoogle() async {
    return await _authService.signInWithGoogle();
  }

  Future<void> signUp(String email, String password, String name) async {
    UserCredential? credential = await _authService.signUpWithEmailAndPassword(email, password);
    final user = credential?.user;
    if (user != null) {
      // Set display name in auth profile
      try {
        await user.updateDisplayName(name);
      } catch (e) {
        if (kDebugMode) {
          print('Error setting display name: $e');
        }
      }

      // Initialize the Firestore user document
      _currentUserModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      if (_isActive) {
        await _firestore.collection('users').doc(user.uid).set(_currentUserModel!.toMap());
        // Request token and update
        await _fcmService.requestPermission();
        await locator<NotificationService>().requestPermissions();
        final token = await _fcmService.getFcmToken();
        if (token != null) {
          await _updateFcmTokenInFirestore(user.uid, token);
        }
      }
    }
  }

  Future<void> logout() async {
    try {
      final rcService = locator<RevenueCatService>();
      if (rcService.isInitialized) {
        await Purchases.logOut();
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat logOut error: $e');
      }
    }
    await _authService.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> deleteAccount() async {
    if (!_isActive) return;
    final user = _authService.currentUser;
    if (user != null) {
      final uid = user.uid;

      // 1. Delete users/{uid}/quick_exercise_reports subcollection documents
      try {
        final reportsSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('quick_exercise_reports')
            .get();
        final batch = _firestore.batch();
        for (var doc in reportsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (kDebugMode) {
          print('Successfully deleted user quick exercise reports.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting quick exercise reports: $e');
        }
      }

      // 2. Delete UsersFeedback documents where uid matches
      try {
        final feedbackSnapshot = await _firestore
            .collection('UsersFeedback')
            .where('uid', isEqualTo: uid)
            .get();
        final batch = _firestore.batch();
        for (var doc in feedbackSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (kDebugMode) {
          print('Successfully deleted user feedback documents.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting user feedback documents: $e');
        }
      }

      // 3. Delete users/{uid} document from Firestore
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting user document: $e');
        }
      }

      // 4. Delete registered_onboarding/{uid} document from Firestore
      try {
        await _firestore.collection('registered_onboarding').doc(uid).delete();
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting registered onboarding document: $e');
        }
      }

      // 5. Delete Firebase Auth User Account
      await _authService.deleteAccount();
    }
  }

  Future<void> updateProfile({
    required String newName,
    required String newEmail,
    required String? newPhone,
    required bool biometricEnabled,
    required String? newPhotoUrl,
  }) async {
    final user = _authService.currentUser;
    if (user != null) {
      // 1. Update Firebase Auth displayName
      if (newName != user.displayName) {
        try {
          await user.updateDisplayName(newName);
        } catch (e) {
          if (kDebugMode) {
            print('Error updating display name: $e');
          }
        }
      }
      // 2. Update Firebase Auth photoURL
      if (newPhotoUrl != user.photoURL) {
        try {
          await user.updatePhotoURL(newPhotoUrl);
        } catch (e) {
          if (kDebugMode) {
            print('Error updating photo URL: $e');
          }
        }
      }
      // 3. Update Firebase Auth email
      if (newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }
      // 4. Update Firestore user document
      if (_isActive) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': newName,
          'email': newEmail,
          'phone': newPhone,
          'biometricEnabled': biometricEnabled,
          'photoUrl': newPhotoUrl,
        });
      }
      // 5. Update local model
      if (_currentUserModel != null) {
        _currentUserModel = _currentUserModel!.copyWith(
          name: newName,
          email: newEmail,
          phone: newPhone,
          biometricEnabled: biometricEnabled,
          photoUrl: newPhotoUrl,
        );
        _userModelController.add(_currentUserModel);
      }
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user currently logged in.');
    }
  }

  Future<void> submitFeedback({
    required int rating,
    required String thoughts,
  }) async {
    final user = _authService.currentUser;
    if (user != null) {
      final feedbackDoc = {
        'uid': user.uid,
        'name': _currentUserModel?.name ?? user.displayName ?? 'MindFlow User',
        'email': _currentUserModel?.email ?? user.email ?? '',
        'rating': rating,
        'thoughts': thoughts,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (_isActive) {
        await _firestore.collection('UsersFeedback').add(feedbackDoc);
      }
    }
  }

  /// Syncs RevenueCat CustomerInfo directly to Firebase Firestore for the current user
  /// and updates the in-memory UserModel and reactive streams.
  Future<void> syncSubscriptionFromCustomerInfo(CustomerInfo customerInfo) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final parsed = locator<RevenueCatService>().parseSubscriptionData(customerInfo);

    await setPremiumStatus(
      parsed.isPremium,
      purchaseDate: parsed.purchaseDate,
      expirationDate: parsed.expirationDate,
      subscriptionStatus: parsed.status,
      subscriptionPlan: parsed.planIdentifier,
      subscriptionStore: parsed.store,
      willRenew: parsed.willRenew,
    );
  }

  /// Verifies current user subscription validity against expiration timestamp and RevenueCat.
  /// If expired, writes isPremium: false and status: 'expired' to Firestore,
  /// causing all premium features to lock immediately.
  Future<void> checkAndSyncSubscription() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // 1. Quick local check against cached expiration date
    if (_currentUserModel != null && _currentUserModel!.isPremium) {
      final expiration = _currentUserModel!.premiumExpirationDate;
      if (expiration != null && DateTime.now().isAfter(expiration)) {
        AppLogger.w('Detected expired subscription locally for user ${user.uid}. Locking features...');
        await setPremiumStatus(
          false,
          subscriptionStatus: 'expired',
          expirationDate: expiration,
          purchaseDate: _currentUserModel!.premiumPurchaseDate,
          subscriptionPlan: _currentUserModel!.subscriptionPlan,
          subscriptionStore: _currentUserModel!.subscriptionStore,
          willRenew: false,
        );
      }
    }

    // 2. Query RevenueCat for verified CustomerInfo
    try {
      final rcService = locator<RevenueCatService>();
      final customerInfo = await rcService.getCustomerInfo();
      if (customerInfo != null) {
        await syncSubscriptionFromCustomerInfo(customerInfo);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error during checkAndSyncSubscription', e, stackTrace);
    }
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
    final user = _authService.currentUser;
    final status = subscriptionStatus ?? (isPremium ? 'active' : 'expired');

    final dataToSave = <String, dynamic>{
      'isPremium': isPremium,
      'subscriptionStatus': status,
      'premiumPurchaseDate': purchaseDate != null ? Timestamp.fromDate(purchaseDate) : null,
      'premiumExpirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStore': subscriptionStore,
      'subscriptionWillRenew': willRenew,
      'subscriptionLastSyncedAt': FieldValue.serverTimestamp(),
    };

    if (user != null) {
      try {
        if (_isActive) {
          await _firestore.collection('users').doc(user.uid).set(
            dataToSave,
            SetOptions(merge: true),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Firestore error setting premium status: $e');
        }
      }
      if (_currentUserModel != null && _currentUserModel!.uid == user.uid) {
        _currentUserModel = _currentUserModel!.copyWith(
          isPremium: isPremium,
          premiumPurchaseDate: purchaseDate,
          premiumExpirationDate: expirationDate,
          subscriptionStatus: status,
          subscriptionPlan: subscriptionPlan,
          subscriptionStore: subscriptionStore,
          subscriptionWillRenew: willRenew,
        );
        _userModelController.add(_currentUserModel);
      }
    } else {
      if (_currentUserModel != null) {
        _currentUserModel = _currentUserModel!.copyWith(
          isPremium: isPremium,
          premiumPurchaseDate: purchaseDate,
          premiumExpirationDate: expirationDate,
          subscriptionStatus: status,
          subscriptionPlan: subscriptionPlan,
          subscriptionStore: subscriptionStore,
          subscriptionWillRenew: willRenew,
        );
        _userModelController.add(_currentUserModel);
      }
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _fcmSubscription?.cancel();
    _userModelController.close();
  }
}
