import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_data_export.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  test('pulse data export includes real profile and session data', () {
    final PulseUserProfile profile = PulseUserProfile(
      uid: 'test-user',
      email: 'ava@example.com',
      displayName: 'Ava',
      avatarColour: '#EC4899',
      currentStreak: 4,
      longestStreak: 7,
      lastSessionDate: '2026-04-21',
      totalXp: 180,
      currentLevel: 2,
      unlockedBadgeIds: const <String>['first-pulse', 'on-a-roll'],
      referralCode: PulseReferral.generateReferralCode('test-user'),
      referralCount: 3,
      settings: const PulseProfileSettings(
        preferredReminderTime: '18:30',
        dailyRemindersEnabled: true,
        streakRemindersEnabled: false,
        weeklySummaryEnabled: true,
        appearanceMode: PulseAppearanceMode.light,
      ),
      createdAt: DateTime.utc(2026, 4, 1, 8),
      lastSeenAt: DateTime.utc(2026, 4, 21, 20, 30),
    );
    final SwipeSessionRecord session = SwipeSessionRecord(
      sessionId: '2026-04-21',
      date: '2026-04-21',
      completedAt: DateTime.utc(2026, 4, 21, 20, 30),
      responses: <EmotionCardResponse>[
        EmotionCardResponse(
          card: const EmotionCard(
            id: 'calm',
            title: 'Calm',
            headline: '',
            description: '',
            reflectionPrompt: '',
            accentColor: Color(0xFF2ED3E6),
          ),
          decision: EmotionCardDecision.accept,
        ),
        EmotionCardResponse(
          card: const EmotionCard(
            id: 'overwhelm',
            title: 'Overwhelm',
            headline: '',
            description: '',
            reflectionPrompt: '',
            accentColor: Color(0xFFFF7A7A),
          ),
          decision: EmotionCardDecision.reject,
        ),
      ],
      acceptedEmotions: const <String>['Calm'],
      contextSocial: 'Friends',
      contextEnergy: 'Steady',
      contextSleep: 'Good',
    );

    final PulseDataExport export = PulseDataExport(
      profile: profile,
      sessions: <SwipeSessionRecord>[session],
    );
    final Map<String, dynamic> json =
        jsonDecode(export.toPrettyJson()) as Map<String, dynamic>;

    expect(json['profile']['uid'], 'test-user');
    expect(json['profile']['email'], 'ava@example.com');
    expect(json['profile']['displayName'], 'Ava');
    expect(json['settings']['preferredReminderTime'], '18:30');
    expect(json['settings']['weeklySummaryEnabled'], isTrue);
    expect(json['progress']['currentStreak'], 4);
    expect(json['progress']['totalXp'], 180);
    expect(json['referral']['referralCode'], startsWith('PULSE'));
    expect(json['referral']['referralCount'], 3);
    expect(json['unlockedBadgeIds'], <dynamic>['first-pulse', 'on-a-roll']);
    expect(json['sessions'], hasLength(1));
    expect(json['sessions'][0]['sessionId'], '2026-04-21');
    expect(json['sessions'][0]['acceptedEmotions'], <dynamic>['Calm']);
    expect(json['sessions'][0]['contextSocial'], 'Friends');
    expect(json['sessions'][0]['swipes'][0]['emotionId'], 'calm');
    expect(json['sessions'][0]['swipes'][1]['decision'], 'reject');
  });
}
