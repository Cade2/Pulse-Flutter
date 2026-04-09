import 'package:flutter/material.dart';

class PulseStatusView extends StatelessWidget {
  const PulseStatusView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.actionLabel,
    this.onAction,
    this.maxWidth = 460,
    this.footnote,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double maxWidth;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (footnote != null && footnote!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  footnote!,
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PulseLoadingCard extends StatelessWidget {
  const PulseLoadingCard({
    super.key,
    this.titleWidthFactor = 0.34,
    this.lineWidthFactors = const <double>[1, 0.88, 0.56],
    this.height = 132,
  });

  final double titleWidthFactor;
  final List<double> lineWidthFactors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PulseSkeletonBox(height: 18, widthFactor: titleWidthFactor),
              const SizedBox(height: 18),
              for (int index = 0; index < lineWidthFactors.length; index++) ...[
                PulseSkeletonBox(
                  height: 14,
                  widthFactor: lineWidthFactors[index],
                ),
                if (index != lineWidthFactors.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PulseSkeletonBox extends StatelessWidget {
  const PulseSkeletonBox({
    super.key,
    required this.height,
    this.widthFactor = 1,
    this.borderRadius,
  });

  final double height;
  final double widthFactor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 240;
        final double clampedFactor = widthFactor.clamp(0.1, 1).toDouble();

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: maxWidth * clampedFactor,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
