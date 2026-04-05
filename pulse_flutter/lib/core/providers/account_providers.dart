import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/pulse_account_repository.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

final pulseAccountRepositoryProvider = Provider<PulseAccountRepository>((ref) {
  return FirestorePulseAccountRepository(ref.watch(firebaseFirestoreProvider));
});
