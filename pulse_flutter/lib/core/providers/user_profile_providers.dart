import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/user_profile_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final FirebaseFirestore firestore = ref.watch(firebaseFirestoreProvider);
  return UserProfileRepository(firestore);
});
