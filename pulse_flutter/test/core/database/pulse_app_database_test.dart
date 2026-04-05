import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/database/pulse_app_database.dart';

void main() {
  group('PulseAppDatabase', () {
    late PulseAppDatabase database;

    setUp(() {
      database = PulseAppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test('queues pending sessions and keeps them ordered newest first', () async {
      await database.queuePendingSession(
        uid: 'user-1',
        sessionId: '2026-04-03',
        sessionDate: '2026-04-03',
        payloadJson: '{"sessionId":"2026-04-03"}',
        createdAt: DateTime(2026, 4, 3, 8),
      );
      await database.queuePendingSession(
        uid: 'user-1',
        sessionId: '2026-04-04',
        sessionDate: '2026-04-04',
        payloadJson: '{"sessionId":"2026-04-04"}',
        createdAt: DateTime(2026, 4, 4, 8),
      );

      final List<PendingSession> rows = await database
          .watchPendingSessions('user-1')
          .first;

      expect(rows, hasLength(2));
      expect(rows.first.sessionId, '2026-04-04');
      expect(rows.last.sessionId, '2026-04-03');
      expect(rows.first.status, 'pending');
    });

    test('stores cached insights and cached gamification payloads', () async {
      await database.cacheInsights(
        uid: 'user-1',
        cacheKey: 'weekly-overview',
        payloadJson: '{"score":82}',
      );
      await database.cacheGamification(
        uid: 'user-1',
        payloadJson: '{"level":4,"xp":340}',
      );

      final CachedInsight? insight = await database.readCachedInsight(
        uid: 'user-1',
        cacheKey: 'weekly-overview',
      );
      final CachedGamificationData? gamification = await database
          .readCachedGamification('user-1');

      expect(insight?.payloadJson, '{"score":82}');
      expect(gamification?.payloadJson, '{"level":4,"xp":340}');
    });
  });
}
