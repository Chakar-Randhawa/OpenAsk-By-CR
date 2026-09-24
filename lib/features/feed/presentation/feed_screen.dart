import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/question_model.dart';
import '../../../app/providers.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'OpenAsk',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Questions',
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Trending'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _QuestionListFeed(feedType: 'new'),
          _QuestionListFeed(feedType: 'trending'),
          _QuestionListFeed(feedType: 'following'),
        ],
      ),
    );
  }
}

class _QuestionListFeed extends ConsumerWidget {
  final String feedType;
  const _QuestionListFeed({required this.feedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(feedQuestionsProvider(feedType));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedQuestionsProvider(feedType));
      },
      child: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        feedType == 'following'
                            ? 'No questions in followed categories yet'
                            : 'No questions found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedType == 'following'
                            ? 'Follow more categories in Discover to populate this feed.'
                            : 'Be the first to ask a question!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (feedType == 'following')
                        FilledButton.tonal(
                          onPressed: () => context.go('/discover'),
                          child: const Text('Discover Categories'),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () => context.push('/ask'),
                          child: const Text('Ask a Question'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _QuestionFeedCard(question: question);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text('Failed to load questions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$err', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(feedQuestionsProvider(feedType)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionFeedCard extends ConsumerWidget {
  final QuestionModel question;
  const _QuestionFeedCard({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat.yMMMd().format(question.createdAt);

    return InkWell(
      onTap: () => context.push('/question/${question.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author and metadata row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: (question.isAnonymous || question.authorPhotoUrl == null)
                      ? null
                      : NetworkImage(question.authorPhotoUrl!),
                  child: (question.isAnonymous || question.authorPhotoUrl == null)
                      ? Icon(
                          question.isAnonymous ? Icons.masks : Icons.person,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  question.isAnonymous ? 'Anonymous' : question.authorDisplayName,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text('•', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => context.push('/category/${question.categoryId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.categoryName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              question.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Body preview
            Text(
              question.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Footer: answers, views, solved status
            Row(
              children: [
                _StatBadge(
                  icon: Icons.chat_bubble_outline,
                  count: '${question.answerCount}',
                  label: 'answers',
                  isHighlighted: question.answerCount > 0,
                ),
                const SizedBox(width: 14),
                _StatBadge(
                  icon: Icons.visibility_outlined,
                  count: '${question.viewCount}',
                  label: 'views',
                ),
                const SizedBox(width: 14),
                if (question.helpfulAnswerId != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 13, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Solved',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final bool isHighlighted;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isHighlighted ? theme.colorScheme.primary : theme.colorScheme.outline;

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
