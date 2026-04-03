import 'package:flutter/material.dart';

class EmotionCard {
  const EmotionCard({
    required this.id,
    required this.title,
    required this.headline,
    required this.description,
    required this.reflectionPrompt,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String headline;
  final String description;
  final String reflectionPrompt;
  final Color accentColor;
}
