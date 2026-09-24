import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/confirmation_dialog.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog(String uid) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Bookmark Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Flutter Architecture',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = titleController.text.trim();
              if (name.isNotEmpty) {
                final repo = ref.read(bookmarkRepositoryProvider);
                await repo.createCollection(uid, name, description: descController.text.trim());
                ref.invalidate(bookmarkCollectionsProvider(uid));
                if (mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).value;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Questions')),
        body: EmptyStateView(
          icon: Icons.bookmark_border,
          title: 'Sign in to access bookmarks',
          description: 'Save questions to read later or organize into custom collections.',
          buttonText: 'Sign In',
          onButtonPressed: () => context.push('/auth'),
        ),
      );
    }

    final savedQuestionsAsync = ref.watch(savedQuestionsProvider(authUser.uid));
    final collectionsAsync = ref.watch(bookmarkCollectionsProvider(authUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks & Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Collection',
            onPressed: () => _showCreateCollectionDialog(authUser.uid),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Saved Questions'),
            Tab(text: 'Collections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Saved Questions
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savedQuestionsProvider(authUser.uid));
            },
            child: savedQuestionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.bookmark_outline,
                    title: 'No saved questions yet',
                    description: 'Bookmark questions while browsing the feed to view them here.',
                    buttonText: 'Browse Questions',
                    onButtonPressed: () => context.go('/'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return ListTile(
                      title: Text(q.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(q.categoryName, style: TextStyle(color: theme.colorScheme.primary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_remove, size: 20),
                        tooltip: 'Remove bookmark',
                        onPressed: () async {
                          final repo = ref.read(bookmarkRepositoryProvider);
                          await repo.toggleBookmark(q.id, authUser.uid);
                          ref.invalidate(savedQuestionsProvider(authUser.uid));
                        },
                      ),
                      onTap: () => context.push('/question/${q.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // Tab 2: Collections
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkCollectionsProvider(authUser.uid));
            },
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.folder_open_outlined,
                    title: 'No collections created',
                    description: 'Organize your favorite questions by creating topics and folders.',
                    buttonText: 'Create Collection',
                    onButtonPressed: () => _showCreateCollectionDialog(authUser.uid),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.folder, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(col.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: col.description != null ? Text(col.description!) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final confirmed = await ConfirmationDialog.show(
                            context: context,
                            title: 'Delete Collection',
                            content: 'Are you sure you want to delete "${col.title}"?',
                            confirmLabel: 'Delete',
                            isDestructive: true,
                          );
                          if (confirmed) {
                            final repo = ref.read(bookmarkRepositoryProvider);
                            await repo.deleteCollection(col.id, authUser.uid);
                            ref.invalidate(bookmarkCollectionsProvider(authUser.uid));
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
