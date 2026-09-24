import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/category_model.dart';

final categoryQuestionsProvider = FutureProvider.family<List<QuestionModel>, String>((ref, categoryId) async {
  return ref.watch(questionRepositoryProvider).fetchQuestions(
    feedType: 'new',
    categoryId: categoryId,
  );
});

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final questionsAsync = ref.watch(categoryQuestionsProvider(categoryId));
    final followedIdsAsync = ref.watch(followedCategoryIdsProvider);
    final authUser = ref.watch(authStateProvider).value;

    final category = categoriesAsync.value?.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(
        id: categoryId,
        name: 'Category',
        slug: categoryId,
        description: '',
        icon: '📁',
      ),
    );

    final isFollowed = (followedIdsAsync.value ?? <String>{}).contains(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? 'Category'),
        actions: [
          TextButton(
            onPressed: () async {
              if (authUser == null) {
                context.push('/auth');
                return;
              }
              final catRepo = ref.read(categoryRepositoryProvider);
              await catRepo.followCategory(categoryId, authUser.uid);
              ref.invalidate(followedCategoryIdsProvider);
            },
            child: Text(isFollowed ? 'Following' : 'Follow'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(category?.icon ?? '📁', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category?.name ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (category?.description.isNotEmpty == true)
                            Text(category!.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Questions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(categoryQuestionsProvider(categoryId));
              },
              child: questionsAsync.when(
                data: (questions) {
                  if (questions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 56, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          const Text('No questions in this category yet.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.push('/ask'),
                            child: const Text('Ask the First Question'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return ListTile(
                        title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          q.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${q.answerCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('answers', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        onTap: () => context.push('/question/${q.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading questions: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
