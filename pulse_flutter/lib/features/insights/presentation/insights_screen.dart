import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/components/pulse_share_card.dart';
import 'package:pulse_flutter/components/pulse_state_views.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_share_card_data.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/pulse_weekly_pulse_score.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';
import 'package:pulse_flutter/core/providers/insight_providers.dart';
import 'package:pulse_flutter/core/providers/share_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PulseInsightsReport> insightsAsync = ref.watch(
      currentUserInsightsProvider,
    );
    final bool isOffline = ref.watch(isOfflineProvider);
    final PulseStreak streak = ref.watch(currentUserStreakProvider);

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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('open-mood-market-button'),
                              onPressed: () =>
                                  context.goNamed(AppRoutes.moodMarketName),
                              icon: const Icon(Icons.auto_awesome_rounded),
                              label: const Text('Open MoodMarket'),
                            ),
                            OutlinedButton.icon(
                              key: const Key('open-share-card-button'),
                              onPressed: () => _showShareCardSheet(
                                context,
                                ref,
                                PulseShareCardData.fromInsights(
                                  report: report,
                                  streak: streak,
                                ),
                              ),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('Share snapshot'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        _AcceptedEmotionsChartCard(report: report),
                        const SizedBox(height: 16),
                        _ContextBreakdownCard(report: report),
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
                              _SessionRhythmChartCard(report: report),
                              const SizedBox(height: 16),
                              _EmotionContextPatternsCard(report: report),
                              const SizedBox(height: 16),
                              if (report.hasLongHorizonInsights) ...[
                                _EmotionalYearSummaryCard(report: report),
                                const SizedBox(height: 16),
                                _EmotionalYearTimelineCard(report: report),
                              ] else
                                _LongHorizonUnlockCard(report: report),
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
          loading: () => const _InsightsLoadingState(),
          error: (error, stackTrace) {
            return PulseStatusView(
              title: 'Unable to load insights',
              message: isOffline
                  ? 'You\'re offline, so Pulse can\'t refresh the latest insight patterns right now.'
                  : 'Please try again in a moment.',
              footnote: isOffline
                  ? 'Your saved history remains on this device and richer insights will catch up when the connection returns.'
                  : null,
              icon: isOffline
                  ? Icons.cloud_off_rounded
                  : Icons.insights_outlined,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(currentUserInsightsProvider),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showShareCardSheet(
    BuildContext context,
    WidgetRef ref,
    PulseShareCardData shareCardData,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return _ShareCardSheet(
          data: shareCardData,
          onShare: (boundaryKey, sharePositionOrigin) async {
            await ref
                .read(pulseShareCardShareServiceProvider)
                .shareCard(
                  boundaryKey: boundaryKey,
                  data: shareCardData,
                  sharePositionOrigin: sharePositionOrigin,
                );

            messenger.showSnackBar(
              const SnackBar(
                content: Text('Pulse share card prepared for sharing.'),
              ),
            );
          },
          onCopy: () async {
            await Clipboard.setData(
              ClipboardData(text: shareCardData.toShareText()),
            );

            if (!sheetContext.mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            messenger.showSnackBar(
              const SnackBar(content: Text('Pulse share text copied.')),
            );
          },
        );
      },
    );
  }
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              PulseLoadingCard(
                titleWidthFactor: 0.28,
                lineWidthFactors: <double>[0.38, 0.62],
                height: 112,
              ),
              SizedBox(height: 16),
              PulseLoadingCard(
                titleWidthFactor: 0.34,
                lineWidthFactors: <double>[0.3, 0.48],
                height: 116,
              ),
              SizedBox(height: 16),
              PulseLoadingCard(
                titleWidthFactor: 0.4,
                lineWidthFactors: <double>[0.32, 0.66, 0.52],
                height: 144,
              ),
              SizedBox(height: 16),
              PulseLoadingCard(
                titleWidthFactor: 0.26,
                lineWidthFactors: <double>[0.92, 0.76, 0.54],
                height: 172,
              ),
            ],
          ),
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
    final PulseInsightCount? topWeekday = report.mostActiveWeekday;
    final String topEmotionShare = _formatPercent(
      report.acceptedEmotionShare(topEmotion),
    );

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Overview', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          _InsightHighlightCard(
            title: 'Most common mood',
            value: topEmotion?.label ?? 'No signal yet',
            supporting: topEmotion == null
                ? 'Accepted emotions will appear here as your history grows.'
                : '$topEmotionShare of all accepted emotions so far.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InsightMetricChip(
                label: 'Accepted total',
                value: '${report.totalAcceptedEmotions}',
              ),
              _InsightMetricChip(
                label: 'Emotion range',
                value: '${report.uniqueAcceptedEmotionCount}',
              ),
              _InsightMetricChip(
                label: 'Avg per session',
                value: _formatAverage(report.averageAcceptedPerSession),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Total sessions',
            value: '${report.totalSessions}',
            supporting:
                '${report.totalAcceptedEmotions} accepted emotions saved',
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
}

class _ContextBreakdownCard extends StatelessWidget {
  const _ContextBreakdownCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String coverageLabel =
        '${report.sessionsWithContextTags} / ${report.totalSessions} sessions with context';
    final double coverageValue = report.contextCoverageFor(
      report.sessionsWithContextTags,
    );

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Context breakdown', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(coverageLabel, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: coverageValue, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ContextSignalTile(
                label: 'Social',
                value: report.topSocialContext?.label ?? 'No social tags yet',
                supporting:
                    '${report.sessionsWithSocialContext} / ${report.totalSessions} sessions',
              ),
              _ContextSignalTile(
                label: 'Energy',
                value: report.topEnergyTag?.label ?? 'No energy tags yet',
                supporting:
                    '${report.sessionsWithEnergyTag} / ${report.totalSessions} sessions',
              ),
              _ContextSignalTile(
                label: 'Sleep',
                value: report.topSleepTag?.label ?? 'No sleep tags yet',
                supporting:
                    '${report.sessionsWithSleepTag} / ${report.totalSessions} sessions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptedEmotionsChartCard extends StatelessWidget {
  const _AcceptedEmotionsChartCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PulseInsightCount> items = report.acceptedEmotionFrequency
        .take(5)
        .toList(growable: false);

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Top accepted emotions', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Emotion mix', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'A quick view of the emotions you accept most often in Pulse.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Text(
              'No accepted emotions have been saved yet.',
              style: textTheme.bodyMedium,
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InsightBarRow(
                  label: item.label,
                  count: item.count,
                  shareLabel: _formatPercent(report.acceptedEmotionShare(item)),
                  maxCount: items.first.count,
                ),
              );
            }),
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

class _SessionRhythmChartCard extends StatelessWidget {
  const _SessionRhythmChartCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<String> weekdayOrder = const <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final Map<String, PulseInsightCount> countsByDay =
        <String, PulseInsightCount>{
          for (final PulseInsightCount count in report.weekdaySessions)
            count.label: count,
        };
    final int maxCount = report.weekdaySessions.isEmpty
        ? 1
        : report.weekdaySessions.first.count;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Session rhythm', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Weekday pattern', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'See where your saved sessions cluster across the week.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...weekdayOrder.map((day) {
            final PulseInsightCount? count = countsByDay[day];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InsightBarRow(
                label: day,
                count: count?.count ?? 0,
                shareLabel: count == null
                    ? '0%'
                    : _formatPercent(report.weekdayShare(count)),
                maxCount: maxCount,
              ),
            );
          }),
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
    final String weekdayShare = _formatPercent(report.weekdayShare(topWeekday));
    final String emotionShare = _formatPercent(
      report.acceptedEmotionShare(report.topAcceptedEmotion),
    );
    final String contextAnchor = [
      report.topSocialContext?.label,
      report.topEnergyTag?.label,
      report.topSleepTag?.label,
    ].whereType<String>().join(' / ');

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pattern signals', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PatternSignalTile(
                title: 'Weekly rhythm',
                value: topWeekday?.label ?? 'No weekday signal yet',
                supporting: topWeekday == null
                    ? 'A clearer rhythm will appear as more history is saved.'
                    : '$weekdayShare of sessions land here across ${report.activeWeekdayCount} active weekdays.',
              ),
              _PatternSignalTile(
                title: 'Recurring signal',
                value: topPattern == null
                    ? 'No paired signal yet'
                    : '${topPattern.emotion} + ${topPattern.contextTag}',
                supporting:
                    topPattern?.countText ??
                    'A repeated emotion + context pattern will appear once enough context is saved.',
              ),
              _PatternSignalTile(
                title: 'Emotion range',
                value: '${report.uniqueAcceptedEmotionCount} accepted emotions',
                supporting:
                    '${_formatAverage(report.averageAcceptedPerSession)} accepted per session on average, with $emotionShare leaning toward ${report.topAcceptedEmotion?.label ?? 'your top emotion'}.',
              ),
              _PatternSignalTile(
                title: 'Context anchors',
                value: contextAnchor.isEmpty
                    ? 'No strong context yet'
                    : contextAnchor,
                supporting: contextAnchor.isEmpty
                    ? 'Saved social, energy, and sleep tags will combine here.'
                    : 'Most common social, energy, and sleep signals so far.',
              ),
            ],
          ),
        ],
      ),
    );
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

class _LongHorizonUnlockCard extends StatelessWidget {
  const _LongHorizonUnlockCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int progress = report.progressToward(
      PulseInsightsReport.longHorizonUnlockSessionCount,
    );
    final double progressValue =
        progress / PulseInsightsReport.longHorizonUnlockSessionCount;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Emotional year unlocks at 30 sessions',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '$progress / ${PulseInsightsReport.longHorizonUnlockSessionCount} sessions',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progressValue, minHeight: 8),
          ),
          const SizedBox(height: 12),
          Text(
            report.sessionsUntilLongHorizon == 1
                ? 'Save 1 more session to unlock your long-horizon emotional year view.'
                : 'Save ${report.sessionsUntilLongHorizon} more sessions to unlock your long-horizon emotional year view.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmotionalYearSummaryCard extends StatelessWidget {
  const _EmotionalYearSummaryCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PulseInsightMonthSummary? mostActiveMonth = report.mostActiveMonth;
    final PulseInsightCount? rarestEmotion = report.rarestAcceptedEmotion;
    final PulseInsightTrend? monthTrend = report.monthOverMonthTrend;

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Emotional year', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${report.activeMonthCount} active months tracked',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This longer-horizon layer looks across the months already saved in Pulse.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Most active month',
            value: mostActiveMonth?.label ?? 'No month signal yet',
            supporting: mostActiveMonth == null
                ? 'Monthly activity will appear here once more history is saved.'
                : mostActiveMonth.sessionCountText,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Rarest emotion',
            value: rarestEmotion?.label ?? 'No accepted emotions yet',
            supporting:
                rarestEmotion?.countText ??
                'Accepted emotions will surface the rarest signal here.',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Recent month trend',
            value: monthTrend?.label ?? 'Need 2 active months',
            supporting: monthTrend == null
                ? 'A month-over-month trend appears once two active months are saved.'
                : '${monthTrend.currentLabel} compared with ${monthTrend.previousLabel}.',
          ),
        ],
      ),
    );
  }
}

class _EmotionalYearTimelineCard extends StatelessWidget {
  const _EmotionalYearTimelineCard({required this.report});

  final PulseInsightsReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PulseInsightMonthSummary> months = report.recentMonthlySummaries;
    final int maxCount = months.isEmpty
        ? 1
        : months
              .map((summary) => summary.sessionCount)
              .reduce((lhs, rhs) => lhs > rhs ? lhs : rhs);

    return _InsightsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Monthly pulse trail', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Recent months, their session volume, and the top emotion each month.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...months.map((summary) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _InsightBarRow(
                label: summary.label,
                count: summary.sessionCount,
                shareLabel: summary.topEmotion ?? 'No accepted emotions',
                maxCount: maxCount,
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

class _InsightHighlightCard extends StatelessWidget {
  const _InsightHighlightCard({
    required this.title,
    required this.value,
    required this.supporting,
  });

  final String title;
  final String value;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(supporting, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InsightMetricChip extends StatelessWidget {
  const _InsightMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ContextSignalTile extends StatelessWidget {
  const _ContextSignalTile({
    required this.label,
    required this.value,
    required this.supporting,
  });

  final String label;
  final String value;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 148, maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(supporting, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternSignalTile extends StatelessWidget {
  const _PatternSignalTile({
    required this.title,
    required this.value,
    required this.supporting,
  });

  final String title;
  final String value;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 248),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(supporting, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBarRow extends StatelessWidget {
  const _InsightBarRow({
    required this.label,
    required this.count,
    required this.shareLabel,
    required this.maxCount,
  });

  final String label;
  final int count;
  final String shareLabel;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final double fillRatio = maxCount <= 0 ? 0 : count / maxCount;
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth - 96;
        final double clampedWidth = availableWidth > 0 ? availableWidth : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: textTheme.bodyLarge)),
                const SizedBox(width: 12),
                Text('$count', style: textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(shareLabel, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: clampedWidth * fillRatio,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.data,
    required this.onShare,
    required this.onCopy,
  });

  final PulseShareCardData data;
  final Future<void> Function(GlobalKey boundaryKey, Rect? sharePositionOrigin)
  onShare;
  final Future<void> Function() onCopy;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final GlobalKey _shareCardBoundaryKey = GlobalKey();
  bool _isSharing = false;
  String? _shareErrorMessage;

  Future<void> _handleSharePressed() async {
    setState(() {
      _isSharing = true;
      _shareErrorMessage = null;
    });

    try {
      final RenderObject? renderObject = context.findRenderObject();
      final RenderBox? box = renderObject is RenderBox ? renderObject : null;
      final Rect? sharePositionOrigin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      await widget.onShare(_shareCardBoundaryKey, sharePositionOrigin);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _shareErrorMessage =
            'Unable to share the Pulse card right now. You can still copy the text version.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
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
              'Share your Pulse snapshot',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview the share card, share the image, or copy a text version.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _shareCardBoundaryKey,
                  child: PulseShareCard(data: widget.data),
                ),
              ),
            ),
            if (_shareErrorMessage != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _shareErrorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('share-card-image-button'),
              onPressed: _isSharing ? null : _handleSharePressed,
              icon: _isSharing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(
                _isSharing ? 'Preparing share card...' : 'Share image',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSharing ? null : widget.onCopy,
              child: const Text('Copy share text'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSharing ? null : () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
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

String _formatAverage(double value) {
  final bool isWholeNumber = value == value.roundToDouble();
  return isWholeNumber ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

String _formatPercent(double value) {
  final int percent = (value * 100).round();
  return '$percent%';
}
