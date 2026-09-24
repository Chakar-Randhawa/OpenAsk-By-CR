import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/achievement_model.dart';

class AchievementsScreen extends ConsumerWidget {
  final String uid;
  const AchievementsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(userContributionStatsProvider(uid));
    final achievementsAsync = ref.watch(userAchievementsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust & Achievements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reputation Hero Card
          statsAsync.when(
            data: (stats) => Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.calculatedReputation}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified Community Reputation',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(label: 'Helpful', value: '${stats.helpfulAnswers}'),
                        _StatColumn(label: 'Answers', value: '${stats.totalAnswers}'),
                        _StatColumn(label: 'Questions', value: '${stats.totalQuestions}'),
                        _StatColumn(
                          label: 'Rate',
                          value: '${stats.helpfulPercentage.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading stats: $e'),
          ),

          const SizedBox(height: 24),
          Text(
            'Contribution Milestones & Badges',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          achievementsAsync.when(
            data: (achievements) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final badge = achievements[index];
                  final isUnlocked = badge.isUnlocked;

                  return Card(
                    color: isUnlocked
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUnlocked
                            ? Colors.amber.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(badge.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(
                        badge.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? null : theme.colorScheme.outline,
                        ),
                      ),
                      subtitle: Text(badge.description),
                      trailing: isUnlocked
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                          : const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading achievements: $e'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
