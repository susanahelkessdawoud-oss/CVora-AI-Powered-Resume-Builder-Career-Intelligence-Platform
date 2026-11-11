import 'package:flutter/material.dart';

/// A compact circular gauge showing a 0–100 resume completeness score.
class ScoreIndicator extends StatelessWidget {
  final int score;
  final String label;
  final double size;

  const ScoreIndicator({
    super.key,
    required this.score,
    required this.label,
    this.size = 64,
  });

  Color _colorFor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (score >= 80) return Colors.green;
    if (score >= 60) return scheme.primary;
    if (score >= 40) return Colors.orange;
    return scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text('$score',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resume strength',
                style: Theme.of(context).textTheme.bodySmall),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
