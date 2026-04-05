import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firebase/firebase_auth_service.dart';
import 'package:pulse_flutter/core/firebase/social_auth_clients.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInClientProvider = Provider<PulseGoogleSignInClient>((ref) {
  return PulseGoogleSignInClientImpl();
});

final appleSignInClientProvider = Provider<PulseAppleSignInClient>((ref) {
  return const PulseAppleSignInClientImpl();
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final FirebaseAuth firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthService(
    firebaseAuth,
    googleSignInClient: ref.watch(googleSignInClientProvider),
    appleSignInClient: ref.watch(appleSignInClientProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final FirebaseAuthService authService = ref.watch(
    firebaseAuthServiceProvider,
  );
  return authService.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  final AsyncValue<User?> authState = ref.watch(authStateChangesProvider);
  final FirebaseAuthService authService = ref.watch(
    firebaseAuthServiceProvider,
  );

  return authState.maybeWhen(
    data: (User? user) => user,
    orElse: () => authService.currentUser,
  );
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
