import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/features/swipe_session/data/mock_emotion_cards.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final List<EmotionCardResponse> _responses = <EmotionCardResponse>[];

  int get _currentIndex => _responses.length;

  EmotionCard get _currentCard => mockEmotionCards[_currentIndex];

  void _recordDecision(EmotionCardDecision decision) {
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
        AppRoutes.swipeSessionCompleteName,
        extra: SwipeSessionSummary(responses: updatedResponses),
      );
      return;
    }

    setState(() {
      _responses
        ..clear()
        ..addAll(updatedResponses);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 320),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: card.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: card.accentColor.withValues(alpha: 0.5),
                        ),
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
                            Text(
                              card.headline,
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(card.description, style: textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            Text(
                              card.reflectionPrompt,
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _recordDecision(EmotionCardDecision.reject);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            _recordDecision(EmotionCardDecision.accept);
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
