import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';

enum EmotionCardDecision { accept, reject }

class EmotionCardResponse {
  const EmotionCardResponse({required this.card, required this.decision});

  final EmotionCard card;
  final EmotionCardDecision decision;
}

class SwipeSessionSummary {
  const SwipeSessionSummary({required this.responses});

  final List<EmotionCardResponse> responses;

  int get totalCards => responses.length;

  int get acceptedCount {
    return responses
        .where((response) => response.decision == EmotionCardDecision.accept)
        .length;
  }

  int get rejectedCount {
    return responses
        .where((response) => response.decision == EmotionCardDecision.reject)
        .length;
  }

  List<String> get acceptedEmotions {
    return responses
        .where((response) => response.decision == EmotionCardDecision.accept)
        .map((response) => response.card.title)
        .toList(growable: false);
  }
}
