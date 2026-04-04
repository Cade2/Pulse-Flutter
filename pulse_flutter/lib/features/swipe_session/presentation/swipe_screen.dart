import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/data/mock_emotion_cards.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  static const Duration _swipeResetDuration = Duration(milliseconds: 180);
  static const double _swipeThreshold = 110;

  final List<EmotionCardResponse> _responses = <EmotionCardResponse>[];

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimatingDecision = false;

  int get _currentIndex => _responses.length;

  EmotionCard get _currentCard => mockEmotionCards[_currentIndex];

  double get _dragProgress {
    return (_dragOffset.dx / _swipeThreshold).clamp(-1.0, 1.0);
  }

  void _applyDecision(EmotionCardDecision decision) {
    final EmotionCardResponse response = EmotionCardResponse(
      card: _currentCard,
      decision: decision,
    );

    final List<EmotionCardResponse> updatedResponses = <EmotionCardResponse>[
      ..._responses,
      response,
    ];

    if (updatedResponses.length == mockEmotionCards.length) {
      context.goNamed(
        AppRoutes.contextTagsName,
        extra: SwipeSessionSummary(responses: updatedResponses),
      );
      return;
    }

    setState(() {
      _responses
        ..clear()
        ..addAll(updatedResponses);
      _dragOffset = Offset.zero;
      _isDragging = false;
      _isAnimatingDecision = false;
    });
  }

  Future<void> _completeSwipeDecision(EmotionCardDecision decision) async {
    if (_isAnimatingDecision) {
      return;
    }

    final double dismissDistance =
        MediaQuery.sizeOf(context).width *
        (decision == EmotionCardDecision.accept ? 1.0 : -1.0);

    setState(() {
      _isAnimatingDecision = true;
      _isDragging = false;
      _dragOffset = Offset(dismissDistance, 0);
    });

    await Future<void>.delayed(_swipeResetDuration);

    if (!mounted) {
      return;
    }

    _applyDecision(decision);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimatingDecision) {
      return;
    }

    setState(() {
      _isDragging = true;
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimatingDecision) {
      return;
    }

    final double horizontalOffset = _dragOffset.dx;

    if (horizontalOffset >= _swipeThreshold) {
      _completeSwipeDecision(EmotionCardDecision.accept);
      return;
    }

    if (horizontalOffset <= -_swipeThreshold) {
      _completeSwipeDecision(EmotionCardDecision.reject);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  void _handleHorizontalDragCancel() {
    if (_isAnimatingDecision) {
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SwipeSessionRecord?> todaySessionAsync = ref.watch(
      todaySwipeSessionProvider,
    );

    if (todaySessionAsync.isLoading && !todaySessionAsync.hasValue) {
      return const _SwipeSessionStatusScaffold(
        title: 'Checking today\'s session',
        message:
            'We\'re making sure your daily Pulse session is available before you begin.',
        showLoading: true,
      );
    }

    if (todaySessionAsync.hasError && !todaySessionAsync.hasValue) {
      return const _SwipeSessionStatusScaffold(
        title: 'Session unavailable',
        message:
            'We couldn\'t confirm today\'s session right now. Please return home and try again.',
      );
    }

    final SwipeSessionRecord? todaySession = todaySessionAsync.asData?.value;
    if (todaySession != null) {
      return _DoneForTodayScaffold(session: todaySession);
    }

    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final EmotionCard card = _currentCard;
    final double progress = (_currentIndex + 1) / mockEmotionCards.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse session')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of ${mockEmotionCards.length}',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Accepted ${_acceptedCount()} | Rejected ${_rejectedCount()}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    key: const Key('swipe-session-card'),
                    onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                    onHorizontalDragCancel: _handleHorizontalDragCancel,
                    child: AnimatedContainer(
                      duration: _isDragging
                          ? Duration.zero
                          : _swipeResetDuration,
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(_dragOffset.dx, 0, 0)
                        ..rotateZ(_dragOffset.dx / 1800),
                      transformAlignment: Alignment.center,
                      child: _SwipeCard(
                        card: card,
                        dragProgress: _dragProgress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAnimatingDecision
                              ? null
                              : () {
                                  _applyDecision(EmotionCardDecision.reject);
                                },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isAnimatingDecision
                              ? null
                              : () {
                                  _applyDecision(EmotionCardDecision.accept);
                                },
                          icon: const Icon(Icons.favorite_rounded),
                          label: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _acceptedCount() {
    return _responses
        .where((response) => response.decision == EmotionCardDecision.accept)
        .length;
  }

  int _rejectedCount() {
    return _responses
        .where((response) => response.decision == EmotionCardDecision.reject)
        .length;
  }
}

class _SwipeSessionStatusScaffold extends StatelessWidget {
  const _SwipeSessionStatusScaffold({
    required this.title,
    required this.message,
    this.showLoading = false,
  });

  final String title;
  final String message;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse session')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLoading) ...[
                    const Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    title,
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: showLoading
                        ? null
                        : () => context.goNamed(AppRoutes.homeName),
                    child: const Text('Return home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneForTodayScaffold extends StatelessWidget {
  const _DoneForTodayScaffold({required this.session});

  final SwipeSessionRecord session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse session')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Done for today',
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Today\'s Pulse session has already been completed. Come back tomorrow for another check-in.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Accepted today: ${session.acceptedCount}',
                            style: textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (session.acceptedEmotions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: session.acceptedEmotions
                                  .map((emotion) {
                                    return Chip(label: Text(emotion));
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.goNamed(AppRoutes.homeName),
                    child: const Text('Return home'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.goNamed(AppRoutes.historyName),
                    child: const Text('View history'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({required this.card, required this.dragProgress});

  final EmotionCard card;
  final double dragProgress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double positiveDrag = dragProgress > 0 ? dragProgress : 0;
    final double negativeDrag = dragProgress < 0 ? -dragProgress : 0;

    return Stack(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: card.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: card.accentColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: card.accentColor.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      card.title,
                      style: textTheme.labelLarge?.copyWith(
                        color: card.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(card.headline, style: textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Text(card.description, style: textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Text(card.reflectionPrompt, style: textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Opacity(
            opacity: negativeDrag,
            child: _SwipeIndicator(
              label: 'REJECT',
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Opacity(
            opacity: positiveDrag,
            child: _SwipeIndicator(label: 'ACCEPT', color: card.accentColor),
          ),
        ),
      ],
    );
  }
}

class _SwipeIndicator extends StatelessWidget {
  const _SwipeIndicator({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
