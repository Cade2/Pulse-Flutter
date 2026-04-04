import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class SwipeSessionSaveResult {
  const SwipeSessionSaveResult({
    required this.session,
    required this.xpEarned,
    required this.levelProgress,
  });

  final SwipeSessionRecord session;
  final int xpEarned;
  final PulseLevelProgress levelProgress;
}
