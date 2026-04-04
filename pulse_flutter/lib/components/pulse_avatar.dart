import 'package:flutter/material.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

class PulseAvatar extends StatelessWidget {
  const PulseAvatar({
    super.key,
    required this.initial,
    required this.avatarColour,
    this.radius = 28,
  });

  final String initial;
  final String avatarColour;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = PulseUserProfile.colorFromHex(avatarColour);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.18),
        border: Border.all(color: accentColor.withValues(alpha: 0.7)),
      ),
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Center(
          child: Text(
            initial,
            style: textTheme.titleLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
