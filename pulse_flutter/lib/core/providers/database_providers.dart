import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/database/pulse_app_database.dart';

final pulseAppDatabaseProvider = Provider<PulseAppDatabase>((ref) {
  final PulseAppDatabase database = PulseAppDatabase.inMemory();
  ref.onDispose(database.close);
  return database;
});
