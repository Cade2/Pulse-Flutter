import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/pulse_weekly_pulse_score.dart';
import 'package:pulse_flutter/core/providers/insight_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PulseInsightsReport> insightsAsync = ref.watch(
      currentUserInsightsProvider,
    );
    final PulseStreak streak = ref.watch(currentUserStreakProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: SafeArea(
        child: insightsAsync.when(
          data: (report) {
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InsightsSummaryCard(report: report),
                      const SizedBox(height: 16),
                      _StreakSummaryCard(streak: streak),
                      const SizedBox(height: 16),
                      _WeeklyPulseScoreCard(
                        currentWeekScore: report.currentWeekScore,
                        weeklyScoreTrend: report.weeklyScoreTrend,
                      ),
                      const SizedBox(height: 24),
                      if (!report.hasBasicInsights)
                        _LockedInsightsCard(report: report)
                      else ...[
                        _OverviewCard(report: report),
                        const SizedBox(height: 16),
                        _ContextBreakdownCard(report: report),
                        const SizedBox(height: 16),
                        _InsightListCard(
                          title: 'Top accepted emotions',
                          items: report.acceptedEmotionFrequency
                              .take(5)
                              .toList(growable: false),
                          emptyMessage:
                              'No accepted emotions have been saved yet.',
                        ),
                        const SizedBox(height: 16),
                        _InsightListCard(
                          title: 'Most common context tags',
                          items: report.commonContextTags
                              .take(4)
                              .toList(growable: false),
                          emptyMessage: 'No context tags have been saved yet.',
                        ),
                        const SizedBox(height: 16),
                        if (report.hasExpandedInsights)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ExpandedPatternsCard(report: report),
                              const SizedBox(height: 16),
                              _InsightListCard(
                                title: 'Session rhythm',
                                items: report.weekdaySessions,
                                emptyMessage:
                                    'A weekday rhythm will appear once enough sessions are saved.',
                              ),
                              const SizedBox(height: 16),
                              _EmotionContextPatternsCard(report: report),
                            ],
                          )
                        else
                          _ExpandedUnlockCard(report: report),
                      ],
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Unable to load insights',
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
}

class _InsightsSummaryCard extends StatelessWidget {
  const _InsightsSummaryCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pulse insights', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${report.totalSessions} sessions saved overall',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            report.hasExpandedInsights
                ? 'Expanded patterns are unlocked from your saved Pulse history.'
                : report.hasBasicInsights
                ? 'Your first Pulse patterns are ready, with deeper context unlocking at 14 sessions.'
                : 'Insights unlock after 5 saved sessions.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard({required this.streak});

  final PulseStreak streak;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int currentStreak = streak.currentStreak;
    final int longestStreak = streak.longestStreak;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Current streak', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            currentStreak == 0
                ? '0 days'
                : '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            currentStreak == 0
                ? 'No active streak yet. Your next check-in will restart the chain.'
                : 'You are keeping Pulse alive day by day.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Longest streak',
            value: longestStreak == 0 ? '0 days' : '$longestStreak days',
            supporting: 'Best run recorded so far.',
          ),
        ],
      ),
    );
  }
}

class _WeeklyPulseScoreCard extends StatelessWidget {
  const _WeeklyPulseScoreCard({
    required this.currentWeekScore,
    required this.weeklyScoreTrend,
  });

  final PulseWeeklyPulseScore currentWeekScore;
  final PulseWeeklyPulseScoreTrend? weeklyScoreTrend;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Weekly Pulse Score', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(currentWeekScore.scoreLabel, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            currentWeekScore.dataAvailabilityLabel,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            currentWeekScore.dataAvailabilityMessage,
            style: textTheme.bodyMedium,
          ),
          if (weeklyScoreTrend != null) ...[
            const SizedBox(height: 16),
            _InsightRow(
              label: 'Week over week',
              value: weeklyScoreTrend!.label,
              supporting:
                  'Compared with the previous saved week of Pulse history.',
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedInsightsCard extends StatelessWidget {
  const _LockedInsightsCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final int progress = report.progressToward(
      PulseInsightsReport.basicUnlockSessionCount,
    );
    final double progressValue =
        progress / PulseInsightsReport.basicUnlockSessionCount;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Insights are locked', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '$progress / ${PulseInsightsReport.basicUnlockSessionCount} sessions',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progressValue, minHeight: 8),
          ),
          const SizedBox(height: 12),
          Text(
            report.sessionsUntilBasic == 1
                ? 'Save 1 more session to unlock your first Pulse insights.'
                : 'Save ${report.sessionsUntilBasic} more sessions to unlock your first Pulse insights.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PulseInsightCount? topEmotion = report.topAcceptedEmotion;
    final PulseInsightCount? topContextTag = report.topContextTag;
    final PulseInsightCount? topWeekday = report.mostActiveWeekday;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Overview', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Total sessions',
            value: '${report.totalSessions}',
            supporting:
                '${report.totalAcceptedEmotions} accepted emotions saved',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Average accepted per session',
            value: _formatAverage(report.averageAcceptedPerSession),
            supporting: 'Across your saved Pulse history so far.',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Top emotion',
            value: topEmotion?.label ?? 'No signal yet',
            supporting: topEmotion == null
                ? 'Accepted emotions will appear here as your history grows.'
                : '${topEmotion.countText} across saved sessions',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most common context',
            value: topContextTag?.label ?? 'No context yet',
            supporting: topContextTag == null
                ? 'Optional context tags will appear here once they are saved.'
                : topContextTag.countText,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most active weekday',
            value: topWeekday?.label ?? 'No rhythm yet',
            supporting: topWeekday == null
                ? 'Weekday patterns will appear once more history is saved.'
                : topWeekday.countText,
          ),
        ],
      ),
    );
  }

  String _formatAverage(double value) {
    final bool isWholeNumber = value == value.roundToDouble();
    return isWholeNumber ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _ContextBreakdownCard extends StatelessWidget {
  const _ContextBreakdownCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Context breakdown', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Social context',
            value: report.topSocialContext?.label ?? 'No social tags yet',
            supporting:
                report.topSocialContext?.countText ??
                'Social context will appear here when it is saved.',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Energy pattern',
            value: report.topEnergyTag?.label ?? 'No energy tags yet',
            supporting:
                report.topEnergyTag?.countText ??
                'Energy tags will appear here when they are saved.',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Sleep pattern',
            value: report.topSleepTag?.label ?? 'No sleep tags yet',
            supporting:
                report.topSleepTag?.countText ??
                'Sleep tags will appear here when they are saved.',
          ),
        ],
      ),
    );
  }
}

class _ExpandedUnlockCard extends StatelessWidget {
  const _ExpandedUnlockCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int progress = report.progressToward(
      PulseInsightsReport.expandedUnlockSessionCount,
    );
    final double progressValue =
        progress / PulseInsightsReport.expandedUnlockSessionCount;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'More patterns unlock at 14 sessions',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '$progress / ${PulseInsightsReport.expandedUnlockSessionCount} sessions',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progressValue, minHeight: 8),
          ),
          const SizedBox(height: 12),
          Text(
            report.sessionsUntilExpanded == 1
                ? 'Save 1 more session to unlock deeper context patterns.'
                : 'Save ${report.sessionsUntilExpanded} more sessions to unlock deeper context patterns.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ExpandedPatternsCard extends StatelessWidget {
  const _ExpandedPatternsCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PulseInsightCount? topWeekday = report.mostActiveWeekday;
    final PulseInsightPattern? topPattern = report.topEmotionContextPattern;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pattern signals', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Average accepted per session',
            value: _formatAverage(report.averageAcceptedPerSession),
            supporting: 'Based on your saved Pulse history.',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most active weekday',
            value: topWeekday?.label ?? 'No weekday signal yet',
            supporting: topWeekday?.countText ?? '',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most common social context',
            value: report.topSocialContext?.label ?? 'No social tags yet',
            supporting: report.topSocialContext?.countText ?? '',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most common energy',
            value: report.topEnergyTag?.label ?? 'No energy tags yet',
            supporting: report.topEnergyTag?.countText ?? '',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Most common sleep',
            value: report.topSleepTag?.label ?? 'No sleep tags yet',
            supporting: report.topSleepTag?.countText ?? '',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Strongest emotion + context signal',
            value: topPattern == null
                ? 'No paired signal yet'
                : '${topPattern.emotion} + ${topPattern.contextTag}',
            supporting:
                topPattern?.countText ??
                'A repeated emotion + context signal will appear here when enough context is saved.',
          ),
        ],
      ),
    );
  }

  String _formatAverage(double value) {
    final bool isWholeNumber = value == value.roundToDouble();
    return isWholeNumber ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _EmotionContextPatternsCard extends StatelessWidget {
  const _EmotionContextPatternsCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PulseInsightPattern> patterns = report.emotionContextPatterns
        .take(3)
        .toList(growable: false);

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Repeated emotion + context signals',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (patterns.isEmpty)
            Text(
              'Save sessions with context tags to surface repeated emotion + context pairings.',
              style: textTheme.bodyMedium,
            )
          else
            ...patterns.map((pattern) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightRow(
                  label: pattern.emotion,
                  value: pattern.contextTag,
                  supporting: pattern.countText,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightListCard extends StatelessWidget {
  const _InsightListCard({
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<PulseInsightCount> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(emptyMessage, style: textTheme.bodyMedium)
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightRow(
                  label: item.label,
                  value: '${item.count}',
                  supporting: item.countText,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.child});

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

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
    required this.supporting,
  });

  final String label;
  final String value;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyLarge),
              if (supporting.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(supporting, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: textTheme.titleMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
