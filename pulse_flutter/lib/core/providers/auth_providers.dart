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
  return ref
      .watch(authStateChangesProvider)
      .maybeWhen(data: (User? user) => user, orElse: () => null);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
