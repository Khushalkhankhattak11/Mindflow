import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebaseService;
  final FirebaseAuth? _customFirebaseAuth;

  AuthService({
    required this._firebaseService,
    FirebaseAuth? firebaseAuth,
  })  : _customFirebaseAuth = firebaseAuth;

  bool get _isActive => _firebaseService.isInitialized;

  FirebaseAuth get _auth {
    if (_customFirebaseAuth != null) return _customFirebaseAuth;
    return FirebaseAuth.instance;
  }

  User? get currentUser {
    if (!_isActive) return null;
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (!_isActive) return Stream.value(null);
    return _auth.authStateChanges();
  }

  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    if (!_isActive) {
      throw Exception('Firebase is not initialized. Please configure Firebase first.');
    }
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    if (!_isActive) {
      throw Exception('Firebase is not initialized. Please configure Firebase first.');
    }
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!_isActive) {
      throw Exception('Firebase is not initialized. Please configure Firebase first.');
    }
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled flow

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!_isActive) return;
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isActive) {
      throw Exception('Firebase is not initialized. Please configure Firebase first.');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    if (!_isActive) {
      throw Exception('Firebase is not initialized. Please configure Firebase first.');
    }
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
