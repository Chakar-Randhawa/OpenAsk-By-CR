import 'package:flutter/material.dart';

/// Clean statistic pill for questions and answers.
class StatBadge extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final bool isHighlighted;
  final Color? customColor;

  const StatBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    this.isHighlighted = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = customColor ??
        (isHighlighted ? theme.colorScheme.primary : theme.colorScheme.outline);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
