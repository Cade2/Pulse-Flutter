import 'dart:convert';

import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class PulseDataExport {
  const PulseDataExport({required this.profile, required this.sessions});

  final PulseUserProfile profile;
  final List<SwipeSessionRecord> sessions;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'profile': <String, Object?>{
        'uid': profile.uid,
        'email': profile.email,
        'displayName': profile.displayName,
        'avatarColour': profile.avatarColour,
        'createdAt': profile.createdAt?.toIso8601String(),
        'lastSeenAt': profile.lastSeenAt?.toIso8601String(),
      },
      'settings': profile.settings.toFirestore(),
      'progress': <String, Object?>{
        'currentStreak': profile.currentStreak,
        'longestStreak': profile.longestStreak,
        'lastSessionDate': profile.lastSessionDate,
        'totalXp': profile.totalXp,
        'currentLevel': profile.currentLevel,
      },
      'referral': <String, Object?>{
        'referralCode': PulseReferral.resolveReferralCode(
          profile.referralCode,
          uid: profile.uid,
        ),
        'referralCount': PulseReferral.resolveReferralCount(
          profile.referralCount,
        ),
        'referredByUid': profile.referredByUid,
        'referredByReferralCode': profile.referredByReferralCode,
        'referredAt': profile.referredAt?.toIso8601String(),
      },
      'unlockedBadgeIds': profile.unlockedBadgeIds,
      'sessions': sessions.map(_sessionToJson).toList(growable: false),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  Map<String, Object?> _sessionToJson(SwipeSessionRecord session) {
    return <String, Object?>{
      'sessionId': session.sessionId,
      'date': session.date,
      'completedAt': session.completedAt.toIso8601String(),
      'swipes': session.responses
          .map(
            (response) => <String, String>{
              'emotionId': response.card.id,
              'emotionTitle': response.card.title,
              'decision': response.decision.name,
            },
          )
          .toList(growable: false),
      'acceptedEmotions': session.acceptedEmotions,
      'contextSocial': session.contextSocial,
      'contextEnergy': session.contextEnergy,
      'contextSleep': session.contextSleep,
    };
  }
}
