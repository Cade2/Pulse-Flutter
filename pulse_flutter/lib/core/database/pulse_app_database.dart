import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'pulse_app_database.g.dart';

class PendingSessions extends Table {
  TextColumn get uid => text()();

  TextColumn get sessionId => text()();

  TextColumn get sessionDate => text()();

  TextColumn get payloadJson => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get errorMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid, sessionId};
}

class CachedInsights extends Table {
  TextColumn get uid => text()();

  TextColumn get cacheKey => text()();

  TextColumn get payloadJson => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid, cacheKey};
}

class CachedGamification extends Table {
  TextColumn get uid => text()();

  TextColumn get payloadJson => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid};
}

@DriftDatabase(tables: <Type>[PendingSessions, CachedInsights, CachedGamification])
class PulseAppDatabase extends _$PulseAppDatabase {
  PulseAppDatabase(super.executor);

  factory PulseAppDatabase.openDefault() {
    return PulseAppDatabase(_openConnection());
  }

  factory PulseAppDatabase.inMemory() {
    return PulseAppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  Future<void> queuePendingSession({
    required String uid,
    required String sessionId,
    required String sessionDate,
    required String payloadJson,
    String status = 'pending',
    String? errorMessage,
    DateTime? createdAt,
  }) {
    final DateTime timestamp = createdAt ?? DateTime.now();
    return into(pendingSessions).insertOnConflictUpdate(
      PendingSessionsCompanion.insert(
        uid: uid,
        sessionId: sessionId,
        sessionDate: sessionDate,
        payloadJson: payloadJson,
        status: Value(status),
        errorMessage: Value(errorMessage),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Stream<List<PendingSession>> watchPendingSessions(String uid) {
    return (select(pendingSessions)
          ..where((table) => table.uid.equals(uid))
          ..orderBy(<OrderingTerm Function(PendingSessions)>[
            (table) => OrderingTerm(
              expression: table.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<void> cacheInsights({
    required String uid,
    required String cacheKey,
    required String payloadJson,
    DateTime? updatedAt,
  }) {
    final DateTime timestamp = updatedAt ?? DateTime.now();
    return into(cachedInsights).insertOnConflictUpdate(
      CachedInsightsCompanion.insert(
        uid: uid,
        cacheKey: cacheKey,
        payloadJson: payloadJson,
        updatedAt: timestamp,
      ),
    );
  }

  Future<CachedInsight?> readCachedInsight({
    required String uid,
    required String cacheKey,
  }) {
    return (select(cachedInsights)
          ..where((table) => table.uid.equals(uid))
          ..where((table) => table.cacheKey.equals(cacheKey)))
        .getSingleOrNull();
  }

  Future<void> cacheGamification({
    required String uid,
    required String payloadJson,
    DateTime? updatedAt,
  }) {
    final DateTime timestamp = updatedAt ?? DateTime.now();
    return into(cachedGamification).insertOnConflictUpdate(
      CachedGamificationCompanion.insert(
        uid: uid,
        payloadJson: payloadJson,
        updatedAt: timestamp,
      ),
    );
  }

  Future<CachedGamificationData?> readCachedGamification(String uid) {
    return (select(
      cachedGamification,
    )..where((table) => table.uid.equals(uid))).getSingleOrNull();
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File(p.join(directory.path, 'pulse_local.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
