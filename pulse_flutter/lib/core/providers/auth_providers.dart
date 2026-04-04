import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firebase/firebase_auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final FirebaseAuth firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthService(firebaseAuth);
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
