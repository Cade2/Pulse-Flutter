import 'package:flutter/material.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';

const List<EmotionCard> mockEmotionCards = <EmotionCard>[
  EmotionCard(
    id: 'calm',
    title: 'Calm',
    headline: 'You feel steady and grounded.',
    description:
        'This card fits moments when your mind is clear and your body feels settled.',
    reflectionPrompt: 'Would you like to lean into calm today?',
    accentColor: Color(0xFF2ED3E6),
  ),
  EmotionCard(
    id: 'joy',
    title: 'Joy',
    headline: 'Something light and energising is present.',
    description:
        'Joy can show up as excitement, gratitude, or the urge to share a good moment.',
    reflectionPrompt: 'Does joy feel true for this moment?',
    accentColor: Color(0xFF67F5D7),
  ),
  EmotionCard(
    id: 'focus',
    title: 'Focus',
    headline: 'Your attention wants a clear direction.',
    description:
        'This card captures moments where you want to lock in, simplify, and make progress.',
    reflectionPrompt: 'Would focus support you right now?',
    accentColor: Color(0xFF49A8FF),
  ),
  EmotionCard(
    id: 'hope',
    title: 'Hope',
    headline: 'You can see possibility ahead.',
    description:
        'Hope often appears when things are uncertain but still feel worth moving toward.',
    reflectionPrompt: 'Do you want to keep hope close today?',
    accentColor: Color(0xFF6DDC8A),
  ),
  EmotionCard(
    id: 'confidence',
    title: 'Confidence',
    headline: 'You trust your ability to handle what is next.',
    description:
        'Confidence can be quiet and steady, not only loud or highly visible.',
    reflectionPrompt: 'Does confidence match your current energy?',
    accentColor: Color(0xFFFFB74D),
  ),
  EmotionCard(
    id: 'curiosity',
    title: 'Curiosity',
    headline: 'You want to explore without forcing certainty.',
    description:
        'Curiosity makes room for questions, perspective shifts, and fresh patterns.',
    reflectionPrompt: 'Would curiosity help you move forward?',
    accentColor: Color(0xFF9C88FF),
  ),
  EmotionCard(
    id: 'overwhelm',
    title: 'Overwhelm',
    headline: 'There may be too much arriving at once.',
    description:
        'This card reflects pressure, noise, or emotional load that is hard to hold alone.',
    reflectionPrompt: 'Is overwhelm part of your experience today?',
    accentColor: Color(0xFFFF7A7A),
  ),
  EmotionCard(
    id: 'vulnerability',
    title: 'Vulnerability',
    headline: 'Something tender or exposed needs gentle attention.',
    description:
        'Vulnerability can appear when honesty, closeness, or uncertainty feels especially alive.',
    reflectionPrompt: 'Does vulnerability deserve space right now?',
    accentColor: Color(0xFFF48FB1),
  ),
];
