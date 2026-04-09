import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_mood_market.dart';
import 'package:pulse_flutter/core/providers/insight_providers.dart';

class MoodMarketScreen extends ConsumerStatefulWidget {
  const MoodMarketScreen({super.key});

  @override
  ConsumerState<MoodMarketScreen> createState() => _MoodMarketScreenState();
}

class _MoodMarketScreenState extends ConsumerState<MoodMarketScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advanceStory(int pageCount) async {
    if (_pageIndex >= pageCount - 1) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_pageIndex <= 0) {
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PulseMoodMarketReport> reportAsync = ref.watch(
      currentUserMoodMarketProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('MoodMarket')),
      body: SafeArea(
        child: reportAsync.when(
          data: (report) {
            if (!report.hasSessions) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _MoodMarketCard(
                      colors: const <Color>[
                        Color(0xFF0F3A42),
                        Color(0xFF12232C),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your Pulse Wrapped starts after the first check-in',
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MoodMarket turns real Pulse history into a longer-view emotional story. Save your first session and this space will begin to light up.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final List<Widget> pages = <Widget>[
              _StoryOpeningPage(report: report),
              _TopEmotionsPage(report: report),
              _ShiftStoryPage(report: report),
              _ContextStoryPage(report: report),
              _StrongestSignalsPage(report: report),
            ];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Pulse Wrapped',
                        style: textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A longer-view story shaped from your saved emotional trail.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    key: const Key('mood-market-page-view'),
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
                        child: pages[index],
                      );
                    },
                  ),
                ),
                _MoodMarketPageDots(
                  pageCount: pages.length,
                  activeIndex: _pageIndex,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      if (_pageIndex > 0)
                        TextButton(
                          key: const Key('mood-market-previous-button'),
                          onPressed: _goBack,
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox(width: 64),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: FilledButton(
                          key: const Key('mood-market-next-button'),
                          onPressed: () => _advanceStory(pages.length),
                          child: Text(
                            _pageIndex == pages.length - 1
                                ? 'Start again'
                                : 'Next chapter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        'MoodMarket is unavailable right now',
                        style: textTheme.headlineMedium,
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

class _StoryOpeningPage extends StatelessWidget {
  const _StoryOpeningPage({required this.report});

  final PulseMoodMarketReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _MoodMarketCard(
      colors: const <Color>[Color(0xFF0F4C5C), Color(0xFF1A936F)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoodMarketEyebrow(
            icon: Icons.auto_awesome_rounded,
            label: 'Chapter 1',
          ),
          const SizedBox(height: 18),
          Text(
            'Your Pulse story',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            report.rangeLabel,
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.periodSummary,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MoodMarketStat(
                label: 'Lead emotion',
                value: report.leadingEmotion?.label ?? 'No signal yet',
                supporting: report.leadingEmotionShareLabel(
                  report.leadingEmotion,
                ),
              ),
              _MoodMarketStat(
                label: 'Most active month',
                value: report.mostActiveMonth?.label ?? 'No month yet',
                supporting:
                    report.mostActiveMonth?.sessionCountText ??
                    'More history unlocks this.',
              ),
              _MoodMarketStat(
                label: 'Emotion range',
                value: '${report.insights.uniqueAcceptedEmotionCount}',
                supporting: 'Distinct accepted emotions saved',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopEmotionsPage extends StatelessWidget {
  const _TopEmotionsPage({required this.report});

  final PulseMoodMarketReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PulseInsightCount> topEmotions = report.topEmotions;
    final int maxCount = topEmotions.isEmpty ? 1 : topEmotions.first.count;

    return _MoodMarketCard(
      colors: const <Color>[Color(0xFF3A0CA3), Color(0xFF4CC9F0)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoodMarketEyebrow(icon: Icons.favorite_rounded, label: 'Chapter 2'),
          const SizedBox(height: 18),
          Text(
            'Top emotions',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            report.leadingEmotion?.label ?? 'No accepted emotions yet',
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report.leadingEmotionShareLabel(report.leadingEmotion),
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 24),
          if (topEmotions.isEmpty)
            Text(
              'Accepted emotions will fill this chapter as more sessions are saved.',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )
          else
            ...topEmotions.map((emotion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MoodMarketBar(
                  label: emotion.label,
                  count: emotion.count,
                  maxCount: maxCount,
                  supporting: report.leadingEmotionShareLabel(emotion),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ShiftStoryPage extends StatelessWidget {
  const _ShiftStoryPage({required this.report});

  final PulseMoodMarketReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _MoodMarketCard(
      colors: const <Color>[Color(0xFF264653), Color(0xFFE76F51)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoodMarketEyebrow(
            icon: Icons.swap_horiz_rounded,
            label: 'Chapter 3',
          ),
          const SizedBox(height: 18),
          Text(
            'Shifts and turns',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            report.emotionalShiftHeadline,
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.emotionalShiftSupporting,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 24),
          _MoodMarketFact(
            label: 'Early signal',
            value: report.earlyTopEmotion?.label ?? 'Still forming',
            supporting:
                report.earlyTopEmotion?.countText ??
                'Need more saved emotion history.',
          ),
          const SizedBox(height: 12),
          _MoodMarketFact(
            label: 'Recent signal',
            value: report.recentTopEmotion?.label ?? 'Still forming',
            supporting:
                report.recentTopEmotion?.countText ??
                'Need more saved emotion history.',
          ),
          const SizedBox(height: 12),
          _MoodMarketFact(
            label: 'Recent month trend',
            value: report.monthTrend?.label ?? 'Need two active months',
            supporting: report.monthTrend == null
                ? 'Month-over-month shifts appear once two months have session history.'
                : '${report.monthTrend!.currentLabel} against ${report.monthTrend!.previousLabel}.',
          ),
        ],
      ),
    );
  }
}

class _ContextStoryPage extends StatelessWidget {
  const _ContextStoryPage({required this.report});

  final PulseMoodMarketReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PulseInsightPattern? pattern = report.recurringPattern;

    return _MoodMarketCard(
      colors: const <Color>[Color(0xFF0B132B), Color(0xFF3A506B)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoodMarketEyebrow(
            icon: Icons.travel_explore_rounded,
            label: 'Chapter 4',
          ),
          const SizedBox(height: 18),
          Text(
            'Context anchors',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            pattern == null
                ? 'Your tags are still gathering'
                : '${pattern.emotion} + ${pattern.contextTag}',
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pattern == null
                ? 'Recurring context patterns appear once emotions and context tags overlap across more sessions.'
                : pattern.countText,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MoodMarketStat(
                label: 'Social',
                value: report.topSocialContext?.label ?? 'No social tag yet',
                supporting:
                    report.topSocialContext?.countText ??
                    'No saved social pattern yet.',
              ),
              _MoodMarketStat(
                label: 'Energy',
                value: report.topEnergyTag?.label ?? 'No energy tag yet',
                supporting:
                    report.topEnergyTag?.countText ??
                    'No saved energy pattern yet.',
              ),
              _MoodMarketStat(
                label: 'Sleep',
                value: report.topSleepTag?.label ?? 'No sleep tag yet',
                supporting:
                    report.topSleepTag?.countText ??
                    'No saved sleep pattern yet.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrongestSignalsPage extends StatelessWidget {
  const _StrongestSignalsPage({required this.report});

  final PulseMoodMarketReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _MoodMarketCard(
      colors: const <Color>[Color(0xFF355070), Color(0xFFEAAC8B)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoodMarketEyebrow(icon: Icons.bolt_rounded, label: 'Chapter 5'),
          const SizedBox(height: 18),
          Text(
            'Strongest signals',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            report.leadingEmotion?.label ?? 'No signal yet',
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The emotion that comes through most clearly in your saved Pulse history.',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 24),
          _MoodMarketFact(
            label: 'Lead emotion share',
            value: report.leadingEmotionShareLabel(report.leadingEmotion),
            supporting:
                report.leadingEmotion?.countText ??
                'No accepted emotions have been saved yet.',
          ),
          const SizedBox(height: 12),
          _MoodMarketFact(
            label: 'Rarest emotion',
            value: report.rarestEmotion?.label ?? 'No rare signal yet',
            supporting:
                report.rarestEmotion?.countText ??
                'A rare emotion appears once your accepted set expands.',
          ),
          const SizedBox(height: 12),
          _MoodMarketFact(
            label: 'Most active weekday',
            value: report.mostActiveWeekday?.label ?? 'No weekday rhythm yet',
            supporting:
                report.mostActiveWeekday?.countText ??
                'Weekday rhythm appears after more saved sessions.',
          ),
        ],
      ),
    );
  }
}

class _MoodMarketPageDots extends StatelessWidget {
  const _MoodMarketPageDots({
    required this.pageCount,
    required this.activeIndex,
  });

  final int pageCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (index) {
        final bool isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MoodMarketCard extends StatelessWidget {
  const _MoodMarketCard({required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class _MoodMarketEyebrow extends StatelessWidget {
  const _MoodMarketEyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

class _MoodMarketStat extends StatelessWidget {
  const _MoodMarketStat({
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                supporting,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodMarketFact extends StatelessWidget {
  const _MoodMarketFact({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              supporting,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodMarketBar extends StatelessWidget {
  const _MoodMarketBar({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.supporting,
  });

  final String label;
  final int count;
  final int maxCount;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double ratio = maxCount <= 0 ? 0 : count / maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          supporting,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}
