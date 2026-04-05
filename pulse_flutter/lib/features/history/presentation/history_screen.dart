import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialSessionId});

  final String? initialSessionId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const List<String> _weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  DateTime? _visibleMonth;
  String? _openedInitialSessionId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SwipeSessionRecord>> sessionsAsync = ref.watch(
      userSwipeSessionsProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) {
            _maybeOpenInitialSession(sessions);

            if (sessions.isEmpty) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No sessions yet',
                          style: textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete your first swipe session to start building your Pulse history.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final DateTime currentDate = ref.watch(currentSessionDateProvider);
            final DateTime minMonth = _monthStart(
              sessions
                  .map((session) => session.completedAt)
                  .reduce(_earlierDate),
            );
            final DateTime maxMonth = _monthStart(
              _laterDate(
                currentDate,
                sessions
                    .map((session) => session.completedAt)
                    .reduce(_laterDate),
              ),
            );
            final DateTime preferredMonth =
                _visibleMonth ?? _monthStart(sessions.first.completedAt);
            final DateTime visibleMonth = _clampMonth(
              preferredMonth,
              minMonth,
              maxMonth,
            );
            final List<SwipeSessionRecord> monthSessions = sessions
                .where(
                  (session) => _isSameMonth(session.completedAt, visibleMonth),
                )
                .toList(growable: false);
            final Map<String, SwipeSessionRecord> sessionsByDay =
                <String, SwipeSessionRecord>{
                  for (final SwipeSessionRecord session in monthSessions)
                    session.sessionId: session,
                };
            final bool canGoPreviousMonth = !_isSameMonth(
              visibleMonth,
              minMonth,
            );
            final bool canGoNextMonth = !_isSameMonth(visibleMonth, maxMonth);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            key: const Key('history-previous-month'),
                            tooltip: 'Previous month',
                            onPressed: canGoPreviousMonth
                                ? () {
                                    setState(() {
                                      _visibleMonth = _previousMonth(
                                        visibleMonth,
                                      );
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Session journey',
                                  style: textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMonthLabel(visibleMonth),
                                  key: const Key('history-month-label'),
                                  style: textTheme.headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const Key('history-next-month'),
                            tooltip: 'Next month',
                            onPressed: canGoNextMonth
                                ? () {
                                    setState(() {
                                      _visibleMonth = _nextMonth(visibleMonth);
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        monthSessions.isEmpty
                            ? 'No sessions were saved in this month yet.'
                            : '${monthSessions.length} ${monthSessions.length == 1 ? 'session' : 'sessions'} saved in ${_formatMonthName(visibleMonth.month)}.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _HistoryCalendarCard(
                        weekdayLabels: _weekdayLabels,
                        visibleMonth: visibleMonth,
                        sessionsByDay: sessionsByDay,
                        onTapSession: (session) =>
                            _showSessionDetail(context, session),
                      ),
                      const SizedBox(height: 24),
                      if (monthSessions.isEmpty)
                        _EmptyMonthCard(
                          monthLabel: _formatMonthLabel(visibleMonth),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sessions this month',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...monthSessions.asMap().entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == monthSessions.length - 1
                                      ? 0
                                      : 16,
                                ),
                                child: _SessionHistoryCard(
                                  session: entry.value,
                                  onTap: () =>
                                      _showSessionDetail(context, entry.value),
                                ),
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Unable to load history',
                        style: textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please try again in a moment.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSessionDetail(BuildContext context, SwipeSessionRecord session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _SessionDetailSheet(session: session),
    );
  }

  void _maybeOpenInitialSession(List<SwipeSessionRecord> sessions) {
    final String? initialSessionId = widget.initialSessionId?.trim();
    if (initialSessionId == null ||
        initialSessionId.isEmpty ||
        _openedInitialSessionId == initialSessionId) {
      return;
    }

    SwipeSessionRecord? matchingSession;
    for (final SwipeSessionRecord session in sessions) {
      if (session.sessionId == initialSessionId) {
        matchingSession = session;
        break;
      }
    }

    if (matchingSession == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedInitialSessionId == initialSessionId) {
        return;
      }

      setState(() {
        _openedInitialSessionId = initialSessionId;
        _visibleMonth = _monthStart(matchingSession!.completedAt);
      });
      _showSessionDetail(context, matchingSession!);
    });
  }

  static DateTime _monthStart(DateTime value) {
    return DateTime(value.year, value.month);
  }

  static DateTime _previousMonth(DateTime value) {
    return DateTime(value.year, value.month - 1);
  }

  static DateTime _nextMonth(DateTime value) {
    return DateTime(value.year, value.month + 1);
  }

  static DateTime _clampMonth(
    DateTime value,
    DateTime minMonth,
    DateTime maxMonth,
  ) {
    if (value.isBefore(minMonth)) {
      return minMonth;
    }

    if (value.isAfter(maxMonth)) {
      return maxMonth;
    }

    return _monthStart(value);
  }

  static bool _isSameMonth(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month;
  }

  static DateTime _earlierDate(DateTime left, DateTime right) {
    return left.isBefore(right) ? left : right;
  }

  static DateTime _laterDate(DateTime left, DateTime right) {
    return left.isAfter(right) ? left : right;
  }

  static String _formatMonthLabel(DateTime value) {
    return '${_formatMonthName(value.month)} ${value.year}';
  }

  static String _formatMonthName(int month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }
}

class _HistoryCalendarCard extends StatelessWidget {
  const _HistoryCalendarCard({
    required this.weekdayLabels,
    required this.visibleMonth,
    required this.sessionsByDay,
    required this.onTapSession,
  });

  final List<String> weekdayLabels;
  final DateTime visibleMonth;
  final Map<String, SwipeSessionRecord> sessionsByDay;
  final ValueChanged<SwipeSessionRecord> onTapSession;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime firstDay = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );
    final int dayCount = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final int leadingEmptyDays = firstDay.weekday - DateTime.monday;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Calendar', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: weekdayLabels
                  .map((label) {
                    return Expanded(
                      child: Center(
                        child: Text(label, style: textTheme.labelMedium),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingEmptyDays + dayCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) {
                  return const SizedBox.shrink();
                }

                final int day = index - leadingEmptyDays + 1;
                final DateTime dayDate = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  day,
                );
                final String sessionId = SwipeSessionRecord.sessionIdForDate(
                  dayDate,
                );
                final SwipeSessionRecord? session = sessionsByDay[sessionId];

                return _CalendarDayTile(
                  day: day,
                  session: session,
                  onTap: session == null ? null : () => onTapSession(session),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.day,
    required this.session,
    required this.onTap,
  });

  final int day;
  final SwipeSessionRecord? session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasSession = session != null;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day',
            style: textTheme.titleSmall?.copyWith(
              color: hasSession ? colorScheme.onPrimaryContainer : null,
            ),
          ),
          const Spacer(),
          if (hasSession) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${session!.acceptedCount} accepted',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ] else
            Text(
              'No check-in',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    if (!hasSession) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: content,
      );
    }

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('history-day-${session!.sessionId}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _EmptyMonthCard extends StatelessWidget {
  const _EmptyMonthCard({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No saved sessions', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'There are no check-ins in $monthLabel yet. Move to another month or complete a new Pulse session to keep building your journey.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.session, required this.onTap});

  final SwipeSessionRecord session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.date, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Accepted ${session.acceptedCount} of ${session.totalCards} emotions',
                style: textTheme.bodyLarge,
              ),
              if (session.contextTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  session.contextTags.join(' | '),
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  const _SessionDetailSheet({required this.session});

  final SwipeSessionRecord session;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Session details',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            session.date,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: 'Accepted',
                  value: '${session.acceptedCount}',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Rejected',
                  value: '${session.rejectedCount}',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Cards reviewed',
                  value: '${session.totalCards}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accepted emotions', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                if (session.acceptedEmotions.isEmpty)
                  Text(
                    'No accepted emotions were saved for this session.',
                    style: textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: session.acceptedEmotions
                        .map((emotion) => Chip(label: Text(emotion)))
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Context tags', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                if (session.contextTags.isEmpty)
                  Text(
                    'No context tags were selected for this session.',
                    style: textTheme.bodyMedium,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: session.contextTags
                        .map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(tag, style: textTheme.bodyMedium),
                          );
                        })
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  'This session captured ${session.acceptedCount} accepted emotions out of ${session.totalCards} reviewed.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
