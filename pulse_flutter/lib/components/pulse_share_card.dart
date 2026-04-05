import 'package:flutter/material.dart';
import 'package:pulse_flutter/core/models/pulse_share_card_data.dart';

class PulseShareCard extends StatelessWidget {
  const PulseShareCard({super.key, required this.data});

  final PulseShareCardData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(data.title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(data.subtitle, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ShareMetric(
                    label: 'Weekly Pulse Score',
                    value: data.weeklyScoreLabel,
                    supporting: data.weeklyDataLabel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ShareMetric(
                    label: 'Current streak',
                    value: data.streakLabel,
                    supporting: data.sessionsLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Top emotions', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (data.topEmotions.isEmpty)
              Text(
                'Keep checking in to surface your first recurring emotion patterns.',
                style: textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: data.topEmotions.map((emotion) {
                  return Chip(
                    label: Text('${emotion.label} (${emotion.count})'),
                  );
                }).toList(growable: false),
              ),
            if (data.trendLabel != null) ...[
              const SizedBox(height: 20),
              _ShareMetric(
                label: 'Week-over-week trend',
                value: data.trendLabel!,
                supporting: 'Compared with the previous saved week.',
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Pulse',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareMetric extends StatelessWidget {
  const _ShareMetric({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(value, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(supporting, style: textTheme.bodySmall),
      ],
    );
  }
}
