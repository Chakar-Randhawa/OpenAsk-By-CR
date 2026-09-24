import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/category_model.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final followedIdsAsync = ref.watch(followedCategoryIdsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Categories'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search 50 topics (AI, Tech, Science...)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final filtered = categories.where((cat) {
            if (_searchQuery.isEmpty) return true;
            return cat.name.toLowerCase().contains(_searchQuery) ||
                cat.description.toLowerCase().contains(_searchQuery) ||
                cat.slug.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No categories matching "$_searchQuery"', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final followedSet = followedIdsAsync.value ?? <String>{};

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cat = filtered[index];
              final isFollowed = followedSet.contains(cat.id);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    cat.icon.isNotEmpty ? cat.icon : cat.name.substring(0, 1),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  cat.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: TextButton.tonal(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isFollowed ? theme.colorScheme.surfaceVariant : theme.colorScheme.primaryContainer,
                  ),
                  onPressed: () async {
                    final authUser = ref.read(authStateProvider).value;
                    if (authUser == null) {
                      context.push('/auth');
                      return;
                    }
                    final catRepo = ref.read(categoryRepositoryProvider);
                    await catRepo.followCategory(cat.id, authUser.uid);
                    ref.invalidate(followedCategoryIdsProvider);
                  },
                  child: Text(
                    isFollowed ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFollowed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                onTap: () => context.push('/category/${cat.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading categories: $err')),
      ),
    );
  }
}
