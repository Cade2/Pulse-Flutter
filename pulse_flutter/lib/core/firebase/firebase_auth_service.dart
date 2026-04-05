import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_flutter/core/firebase/social_auth_clients.dart';

class FirebaseAuthService {
  FirebaseAuthService(
    this._firebaseAuth, {
    PulseGoogleSignInClient? googleSignInClient,
    PulseAppleSignInClient? appleSignInClient,
  }) : _googleSignInClient =
           googleSignInClient ?? PulseGoogleSignInClientImpl(),
       _appleSignInClient = appleSignInClient ?? const PulseAppleSignInClientImpl();

  final FirebaseAuth _firebaseAuth;
  final PulseGoogleSignInClient _googleSignInClient;
  final PulseAppleSignInClient _appleSignInClient;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final PulseSocialAuthCredential? socialCredential =
        await _googleSignInClient.signIn();

    if (socialCredential == null) {
      throw PulseSocialAuthException.cancelled('Google');
    }

    final String? idToken = _trimToNull(socialCredential.idToken);
    final String? accessToken = _trimToNull(socialCredential.accessToken);
    if (idToken == null && accessToken == null) {
      throw PulseSocialAuthException.failed(
        'Google',
        message: 'Google sign-in did not return a valid credential.',
      );
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final PulseSocialAuthCredential? socialCredential =
        await _appleSignInClient.signIn();

    if (socialCredential == null) {
      throw PulseSocialAuthException.cancelled('Apple');
    }

    final String? idToken = _trimToNull(socialCredential.idToken);
    final String? accessToken = _trimToNull(socialCredential.accessToken);
    if (idToken == null && accessToken == null) {
      throw PulseSocialAuthException.failed(
        'Apple',
        message: 'Apple sign-in did not return a valid credential.',
      );
    }

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    final UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(credential);

    final String? displayName = _trimToNull(socialCredential.displayName);
    final User? user = userCredential.user;
    if (displayName != null &&
        user != null &&
        _trimToNull(user.displayName) == null) {
      await user.updateDisplayName(displayName);
      await user.reload();
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignInClient.signOut();
  }

  bool get isAuthenticated => currentUser != null;

  String? _trimToNull(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
