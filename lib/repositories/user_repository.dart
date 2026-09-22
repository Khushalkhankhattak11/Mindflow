import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_logger.dart';

/// Repository handling user profile, feelings, and onboarding data.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches the user's saved feeling preference from the `users` collection.
  Future<String?> getUserFeeling(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['feeling'] as String?;
      }
    } catch (e, stackTrace) {
      AppLogger.w('Failed to fetch user feeling from Firestore', e, stackTrace);
    }
    return null;
  }

  /// Fetches the feeling selected during onboarding from `registered_onboarding`.
  Future<String?> getOnboardingFeeling(String uid) async {
    try {
      final doc = await _firestore.collection('registered_onboarding').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final selectedAnswers = doc.data()!['selectedAnswers'] as Map<String, dynamic>?;
        if (selectedAnswers != null) {
          return selectedAnswers['feeling'] as String?;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.w('Failed to fetch onboarding feeling', e, stackTrace);
    }
    return null;
  }

  /// Saves or updates the user's feeling preference in Firestore.
  Future<void> updateUserFeeling(String uid, String feeling) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'feeling': feeling,
      }, SetOptions(merge: true));
      AppLogger.d('Updated user feeling: $feeling for $uid');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save user feeling to Firestore', e, stackTrace);
      rethrow;
    }
  }

  /// Fetches the list of favorited session titles from `users/{uid}` in Firestore.
  Future<List<String>> getFavoriteSessionTitles(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final rawList = doc.data()!['favorites'] as List<dynamic>?;
        if (rawList != null) {
          return rawList.map((e) => e.toString()).toList();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.w('Failed to fetch favorite session titles from Firestore', e, stackTrace);
    }
    return [];
  }

  /// Adds a session title to the `favorites` array in `users/{uid}`.
  Future<void> addFavoriteSession(String uid, String sessionTitle) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'favorites': FieldValue.arrayUnion([sessionTitle]),
      }, SetOptions(merge: true));
      AppLogger.d('Added favorite "$sessionTitle" for user $uid in Firestore');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to add favorite session to Firestore', e, stackTrace);
    }
  }

  /// Removes a session title from the `favorites` array in `users/{uid}`.
  Future<void> removeFavoriteSession(String uid, String sessionTitle) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'favorites': FieldValue.arrayRemove([sessionTitle]),
      }, SetOptions(merge: true));
      AppLogger.d('Removed favorite "$sessionTitle" for user $uid in Firestore');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to remove favorite session from Firestore', e, stackTrace);
    }
  }
}
