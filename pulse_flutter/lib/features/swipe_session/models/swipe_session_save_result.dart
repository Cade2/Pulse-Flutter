import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';

class SwipeSessionSaveResult {
  const SwipeSessionSaveResult({
    required this.session,
    required this.reward,
    this.isPendingSync = false,
  });

  final SwipeSessionRecord session;
  final SwipeSessionRewardDetails reward;
  final bool isPendingSync;

  int get xpEarned => reward.xpEarned;

  PulseLevelProgress get levelProgress => reward.levelProgress;

  PulseStreak get currentStreak => reward.currentStreak;
}
