import 'package:flutter/material.dart';

/// Clean, restrained skeleton loader for questions, feeds, and cards.
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class QuestionCardSkeleton extends StatelessWidget {
  const QuestionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              LoadingSkeleton(width: 28, height: 28, borderRadius: 14),
              SizedBox(width: 10),
              LoadingSkeleton(width: 90, height: 14),
              Spacer(),
              LoadingSkeleton(width: 70, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeleton(width: double.infinity, height: 18),
          const SizedBox(height: 8),
          const LoadingSkeleton(width: 220, height: 14),
          const SizedBox(height: 14),
          Row(
            children: const [
              LoadingSkeleton(width: 60, height: 16),
              SizedBox(width: 16),
              LoadingSkeleton(width: 50, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}
